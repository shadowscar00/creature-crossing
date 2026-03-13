defmodule CreatureCrossing.Nookipedia.WikiScraper do
  @moduledoc """
  Scrapes data from Nookipedia's MediaWiki API (no API key required).
  Fetches page wikitext and image URLs for various AC item categories.
  """

  @base "https://nookipedia.com/w/api.php"
  @placeholder "/images/critter_placeholder.svg"

  # ── Category listing ──

  @doc """
  List all pages in a MediaWiki category with pagination.
  Returns {:ok, [title]} or {:error, reason}.
  """
  def list_category_members(category, opts \\ []) do
    namespace = Keyword.get(opts, :namespace, "0")
    do_list_category_members(category, namespace, nil, [])
  end

  defp do_list_category_members(category, namespace, continue_from, acc) do
    params =
      [
        action: "query",
        format: "json",
        list: "categorymembers",
        cmtitle: category,
        cmnamespace: namespace,
        cmlimit: "500"
      ] ++ if(continue_from, do: [cmcontinue: continue_from], else: [])

    case Req.get(@base, params: params) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        members =
          (get_in(body, ["query", "categorymembers"]) || [])
          |> Enum.map(& &1["title"])

        new_acc = acc ++ members

        case get_in(body, ["continue", "cmcontinue"]) do
          nil -> {:ok, new_acc}
          next -> do_list_category_members(category, namespace, next, new_acc)
        end

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # ── MediaWiki API helpers ──

  defp wiki_query(params) do
    all_params = [action: "query", format: "json"] ++ params

    case Req.get(@base, params: all_params) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body["query"]["pages"]}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Fetch wikitext for a page. Pass a `disambig_hint` to auto-resolve
  disambiguation pages (e.g. :fish, :bug, :sea, :villager).
  """
  def fetch_wikitext(page_title, disambig_hint \\ nil, search_fallback \\ true) do
    case wiki_query(titles: page_title, prop: "revisions", rvprop: "content") do
      {:ok, pages} ->
        case Map.values(pages) do
          [%{"revisions" => [%{"*" => wikitext} | _]} | _] ->
            cond do
              is_disambig?(wikitext) ->
                resolve_disambig(wikitext, disambig_hint)

              disambig_hint && wrong_page?(wikitext, disambig_hint) ->
                resolve_wrongpage(wikitext, disambig_hint)

              true ->
                {:ok, wikitext}
            end

          _ when search_fallback ->
            search_and_retry(page_title, disambig_hint)

          _ ->
            {:error, :not_found}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # When a page isn't found, search the wiki and retry with the best match
  defp search_and_retry(page_title, disambig_hint) do
    # Determine search namespace (708 for items, 0 for critters/villagers)
    {search_term, namespace} =
      if String.starts_with?(page_title, "Item:") do
        clean = page_title
          |> String.replace_prefix("Item:", "")
          |> String.replace(~r/\s*\(New Horizons\)\s*$/, "")
        {clean <> " new horizons", "708"}
      else
        {page_title, "0"}
      end

    params = [
      action: "query", format: "json",
      list: "search", srsearch: search_term,
      srnamespace: namespace, srlimit: "3"
    ]

    case Req.get(@base, params: params) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        results = get_in(body, ["query", "search"]) || []

        case Enum.map(results, & &1["title"]) do
          [best | _] when best != page_title ->
            # Retry with search result, but disable further search to avoid loops
            fetch_wikitext(best, disambig_hint, false)

          _ ->
            {:error, :not_found}
        end

      _ ->
        {:error, :not_found}
    end
  end

  # ── Disambiguation handling ──

  defp is_disambig?(wikitext) do
    String.contains?(String.downcase(wikitext), "{{disambig}}")
  end

  defp wrong_page?(wikitext, hint) do
    has_villager_infobox = String.contains?(wikitext, "{{Infobox Villager") or
                           String.contains?(wikitext, "{{Infobox villager")

    case hint do
      type when type in [:fish, :bug, :sea] ->
        has_villager_infobox or String.contains?(wikitext, "{{Wrongpage")

      :villager ->
        not has_villager_infobox and String.contains?(wikitext, "{{Wrongpage")

      _ ->
        false
    end
  end

  defp resolve_disambig(_wikitext, nil), do: {:error, :disambiguation}

  defp resolve_disambig(wikitext, hint) do
    links =
      Regex.scan(~r/\[\[([^\]|]+)(?:\|[^\]]*)?\]\]/, wikitext)
      |> Enum.map(fn [_, link] -> String.trim(link) end)

    case find_best_disambig_link(links, hint) do
      nil -> {:error, :disambiguation}
      target -> fetch_wikitext(target)
    end
  end

  defp resolve_wrongpage(wikitext, hint) do
    # Extract all Wrongpage arguments as potential redirect targets
    case Regex.run(~r/\{\{Wrongpage\|([^}]+)\}\}/, wikitext) do
      [_, inner] ->
        candidates = String.split(inner, "|") |> Enum.map(&String.trim/1)

        case find_best_disambig_link(candidates, hint) do
          nil -> {:error, :wrong_page}
          target -> fetch_wikitext(target)
        end

      _ ->
        {:error, :wrong_page}
    end
  end

  @disambig_keywords %{
    fish: ["fish"],
    bug: ["bug", "insect"],
    sea: ["creature", "sea creature", "sea_creature", "deep-sea"],
    villager: ["villager"]
  }

  defp find_best_disambig_link(links, hint) do
    keywords = Map.get(@disambig_keywords, hint, [])

    Enum.find(links, fn link ->
      downcased = String.downcase(link)
      Enum.any?(keywords, &String.contains?(downcased, &1))
    end)
  end

  # ── Image resolution ──

  @doc "Resolve multiple image filenames in a single batch request"
  def resolve_image_urls(filenames) when is_list(filenames) do
    filenames
    |> Enum.reject(&is_nil/1)
    |> Enum.chunk_every(50)
    |> Enum.flat_map(&batch_resolve/1)
    |> Map.new()
  end

  defp batch_resolve([]), do: []

  defp batch_resolve(filenames) do
    titles = Enum.map_join(filenames, "|", &("File:#{&1}"))

    case wiki_query(titles: titles, prop: "imageinfo", iiprop: "url") do
      {:ok, pages} ->
        pages
        |> Map.values()
        |> Enum.flat_map(fn
          %{"title" => "File:" <> fname, "imageinfo" => [%{"url" => url} | _]} ->
            [{fname, url}]

          _ ->
            []
        end)

      _ ->
        []
    end
  end

  @doc """
  Get all images associated with a wiki page. Returns a list of filenames.
  Used as a fallback when constructed icon filenames don't resolve.
  """
  def list_page_images(page_title) do
    case wiki_query(titles: page_title, prop: "images", imlimit: "100") do
      {:ok, pages} ->
        pages
        |> Map.values()
        |> Enum.flat_map(fn
          %{"images" => images} ->
            Enum.map(images, fn %{"title" => "File:" <> fname} -> fname end)

          _ ->
            []
        end)

      _ ->
        []
    end
  end

  @doc """
  Try to resolve an icon by constructed filename first. If that fails,
  query the page's image list and find the best match using the given pattern.

  `candidates` is a list of filenames to try in order.
  `page_title` is the wiki page to query for fallback.
  `fallback_pattern` is a regex to match against the page's image list.
  """
  def resolve_icon(candidates, page_title, fallback_pattern) do
    candidates = Enum.reject(candidates, &is_nil/1)

    # Try all candidates in a single batch
    resolved = resolve_image_urls(candidates)

    case Enum.find(candidates, &Map.has_key?(resolved, &1)) do
      nil ->
        # Fallback: query the page's actual images and pattern-match
        fallback_from_page_images(page_title, fallback_pattern)

      found ->
        Map.get(resolved, found, @placeholder)
    end
  end

  defp fallback_from_page_images(page_title, pattern) do
    images = list_page_images(page_title)

    case Enum.find(images, fn img -> Regex.match?(pattern, img) end) do
      nil ->
        @placeholder

      filename ->
        resolved = resolve_image_urls([filename])
        Map.get(resolved, filename, @placeholder)
    end
  end

  # ── Template parsing ──

  @doc "Parse a MediaWiki infobox/template from wikitext"
  def parse_template(wikitext, template_name) do
    pattern = "{{" <> template_name

    case :binary.match(wikitext, pattern) do
      {start, _} ->
        rest = binary_part(wikitext, start, byte_size(wikitext) - start)
        content = extract_balanced_braces(rest)
        parse_template_params(content)

      :nomatch ->
        %{}
    end
  end

  defp extract_balanced_braces(<<"{{", rest::binary>>), do: do_extract(rest, 2, "{{")
  defp extract_balanced_braces(_), do: ""

  defp do_extract(_, 0, acc), do: acc
  defp do_extract("", _, acc), do: acc
  defp do_extract("{{" <> rest, depth, acc), do: do_extract(rest, depth + 2, acc <> "{{")

  defp do_extract("}}" <> rest, depth, acc) do
    if depth <= 2, do: acc <> "}}", else: do_extract(rest, depth - 2, acc <> "}}")
  end

  defp do_extract(<<c::utf8, rest::binary>>, depth, acc) do
    do_extract(rest, depth, acc <> <<c::utf8>>)
  end

  defp parse_template_params(content) do
    inner =
      content
      |> String.replace_prefix("{{", "")
      |> String.replace_suffix("}}", "")

    case String.split(inner, "|", parts: 2) do
      [_, params_str] ->
        split_top_level_pipes(params_str)
        |> Enum.reduce(%{}, fn param, acc ->
          case String.split(param, "=", parts: 2) do
            [key, value] -> Map.put(acc, String.trim(key), clean_value(value))
            _ -> acc
          end
        end)

      _ ->
        %{}
    end
  end

  defp split_top_level_pipes(str) do
    str
    |> String.graphemes()
    |> Enum.reduce({[], "", 0, 0}, fn char, {parts, current, braces, brackets} ->
      cond do
        char == "{" -> {parts, current <> char, braces + 1, brackets}
        char == "}" -> {parts, current <> char, max(braces - 1, 0), brackets}
        char == "[" -> {parts, current <> char, braces, brackets + 1}
        char == "]" -> {parts, current <> char, braces, max(brackets - 1, 0)}
        char == "|" and braces == 0 and brackets == 0 -> {[current | parts], "", 0, 0}
        true -> {parts, current <> char, braces, brackets}
      end
    end)
    |> then(fn {parts, current, _, _} -> Enum.reverse([current | parts]) end)
  end

  defp clean_value(value) do
    value
    |> String.trim()
    |> String.replace(~r/\[\[([^\]|]*\|)?([^\]]*)\]\]/, "\\2")
    |> String.replace(~r/<br\s*\/?>/, ", ")
    |> String.replace(~r/<[^>]+>/, "")
    |> String.trim()
  end

  # ── Category-specific fetchers ──

  def fetch_villager(name) do
    with {:ok, wikitext} <- fetch_wikitext(name, :villager) do
      info = parse_template(wikitext, "Infobox Villager")
      nh_info = parse_template(wikitext, "NHVillagerInfo")

      escaped = Regex.escape(name)

      icon_file = "#{name} NH Villager Icon.png"
      poster_file = "#{name}'s Poster NH Icon.png"

      amiibo_number = find_amiibo_number(wikitext, name)
      amiibo_file =
        if amiibo_number, do: "#{amiibo_number} #{name} amiibo card NA.png", else: nil

      # Resolve all images with fallbacks
      all_files = [icon_file, poster_file, amiibo_file] |> Enum.reject(&is_nil/1)
      resolved = resolve_image_urls(all_files)

      icon_url =
        Map.get_lazy(resolved, icon_file, fn ->
          fallback_from_page_images(name, ~r/#{escaped}.*NH.*Villager.*Icon/i)
        end)

      poster_url =
        Map.get_lazy(resolved, poster_file, fn ->
          fallback_from_page_images(name, ~r/#{escaped}.*Poster.*NH.*Icon/i)
        end)

      amiibo_url =
        if amiibo_file do
          Map.get_lazy(resolved, amiibo_file, fn ->
            fallback_from_page_images(name, ~r/#{escaped}.*amiibo.*card.*NA/i)
          end)
        else
          # No number found — try fallback search directly
          fallback_from_page_images(name, ~r/#{escaped}.*amiibo.*card.*NA/i)
        end

      {:ok,
       %{
         name: name,
         species: normalize_species(info["species"]),
         personality: info["personality"] || "Unknown",
         gender: info["gender"] || "Unknown",
         birthday: parse_birthday(info),
         sign: info["sign"] || "Unknown",
         catchphrase: info["phrase"] || nh_info["catchphrase"] || "Unknown",
         hobby: nh_info["hobby"] || "Unknown",
         icon_url: icon_url,
         poster_url: poster_url,
         amiibo_url: amiibo_url
       }}
    end
  end

  defp find_amiibo_number(wikitext, name) do
    escaped = Regex.escape(name)

    cond do
      match = Regex.run(~r/(\d+)\s+#{escaped}\s+amiibo\s+card\s+NA/i, wikitext) ->
        Enum.at(match, 1)

      match = Regex.run(~r/\|\s*front\s*=\s*(\d+)\s+#{escaped}/i, wikitext) ->
        Enum.at(match, 1)

      match = Regex.run(~r/\|\s*(?:card[_ ]?number|number)\s*=\s*(\d+)/, wikitext) ->
        Enum.at(match, 1)

      true ->
        nil
    end
  end

  defp parse_birthday(info) do
    month = info["birthdaymonth"] || info["birthday-month"] || info["birthday month"]
    day = info["birthday"] || info["birthday-day"]

    case {month, day} do
      {nil, _} -> "Unknown"
      {_, nil} -> "Unknown"
      {m, d} -> "#{m} #{d}"
    end
  end

  def fetch_critter(page_title, type) do
    {template_name, nh_template} =
      case type do
        :fish -> {"Infobox Fish", "NHFishInfo"}
        :bug -> {"Infobox Bug", "NHBugInfo"}
        :sea -> {"Infobox Sea Creature", "NHSeaCreatureInfo"}
      end

    with {:ok, wikitext} <- fetch_wikitext(page_title, type) do
      info = parse_template(wikitext, template_name)
      nh = parse_template(wikitext, nh_template)

      display_name = info["name"] || page_title

      # Use the image field from the NH template — most reliable
      # Fall back to constructing from name, then to page image search
      icon_from_template = nh["image"]
      icon_constructed = "#{title_case(display_name)} NH Icon.png"

      icon_url =
        resolve_icon(
          [icon_from_template, icon_constructed],
          page_title,
          ~r/NH.*Icon\.png$/i
        )

      {sell_special_label, sell_special_name} =
        case type do
          :fish -> {"sell-cj", "C.J."}
          :bug -> {"sell-flick", "Flick"}
          :sea -> {nil, nil}
        end

      rarity = non_empty(nh["rarity"])

      # Parse weather: bugs have explicit field, fish embeds in location, sea N/A
      raw_location = nh["location"] || info["location"] || "Unknown"
      {location, weather} = extract_weather(raw_location, nh["weather"], type)

      {:ok,
       %{
         type: type,
         name: title_case(display_name),
         location: location,
         weather: weather,
         rarity: rarity,
         sell_nook: nh["sell-nook"] || "?",
         sell_special:
           if(sell_special_label, do: nh[sell_special_label], else: nil),
         sell_special_name: sell_special_name,
         time: nh["time"] || "Unknown",
         months_north: nh["n-availability"] || "Unknown",
         months_south: nh["s-availability"] || "Unknown",
         shadow_size: non_empty(nh["shadow-size"]),
         speed: non_empty(nh["shadow-movement"]) || non_empty(nh["speed"]),
         catchphrase: nh["catchphrase"] || "",
         icon_url: icon_url
       }}
    end
  end

  def fetch_item(page_title, icon_suffix \\ "NH Icon.png") do
    with {:ok, wikitext} <- fetch_wikitext(page_title) do
      info = parse_nh_item(wikitext)

      raw_name = info["name"] || strip_page_prefix(page_title)
      icon_name = title_case(raw_name)

      # Build variant label from variation + pattern axes
      variation = info["variation1"]
      pattern = info["pattern1"]

      variant_label =
        case {non_empty(variation), non_empty(pattern)} do
          {nil, nil} -> nil
          {v, nil} -> title_case(v)
          {nil, p} -> title_case(p)
          {v, p} -> "#{title_case(v)} - #{title_case(p)}"
        end

      # Construct candidate filenames in priority order
      candidates =
        if variant_label do
          [
            "#{icon_name} (#{variant_label}) #{icon_suffix}",
            "#{icon_name} #{icon_suffix}"
          ]
        else
          ["#{icon_name} #{icon_suffix}"]
        end

      # Fallback pattern: any NH Icon that isn't a Storage Icon
      fallback = ~r/#{Regex.escape(icon_name)}.*NH Icon\.png$/i

      icon_url = resolve_icon(candidates, page_title, fallback)

      source = derive_source(info)

      {:ok,
       %{
         name: title_case(raw_name),
         buy_price: format_price(info["buy1-price"], info["buy1-currency"]),
         sell_price: "#{info["sell"] || "?"} Bells",
         source: source,
         category: non_empty(info["category"]) || non_empty(info["tag"]) || "Unknown",
         uses: non_empty(info["uses"]),
         variation: variant_label,
         icon_url: icon_url
       }}
    end
  end

  def fetch_food(page_title) do
    with {:ok, wikitext} <- fetch_wikitext(page_title) do
      info = parse_nh_item(wikitext)

      raw_name = info["name"] || strip_page_prefix(page_title)
      icon_name = title_case(raw_name)

      icon_url =
        resolve_icon(
          ["#{icon_name} NH DIY Icon.png"],
          page_title,
          ~r/#{Regex.escape(icon_name)}.*NH.*DIY.*Icon\.png$/i
        )

      recipe = extract_recipe(info)

      {:ok,
       %{
         name: title_case(raw_name),
         sell_price: "#{info["sell"] || "?"} Bells",
         source: "Cooking",
         energy: info["energy-points"] || "?",
         recipe: recipe,
         icon_url: icon_url
       }}
    end
  end

  def fetch_ingredient(page_title) do
    with {:ok, wikitext} <- fetch_wikitext(page_title) do
      info = parse_nh_item(wikitext)

      raw_name = info["name"] || strip_page_prefix(page_title)
      icon_name = title_case(raw_name)

      icon_url =
        resolve_icon(
          ["#{icon_name} NH Inv Icon.png", "#{icon_name} NH Icon.png"],
          page_title,
          ~r/#{Regex.escape(icon_name)}.*NH.*(Inv|Icon).*\.png$/i
        )

      {:ok,
       %{
         name: title_case(raw_name),
         sell_price: "#{info["sell"] || "?"} Bells",
         stack: info["stack"] || "?",
         energy: info["energy-points"] || "?",
         icon_url: icon_url
       }}
    end
  end

  # ── Shared helpers ──

  # Parse any NH item template — pick the one with the most fields
  # (guards against partial matches like NHFurnitureVillagers matching "NHFurniture")
  defp parse_nh_item(wikitext) do
    ["NHFurniture", "NHClothing", "NHTools", "NHItems"]
    |> Enum.map(fn tpl -> parse_template(wikitext, tpl) end)
    |> Enum.max_by(&map_size/1, fn -> %{} end)
  end

  defp title_case(nil), do: ""

  defp title_case(str) do
    str
    |> String.split(" ")
    |> Enum.map_join(" ", fn word ->
      word
      |> String.split("-")
      |> Enum.map_join("-", fn part ->
        # Handle apostrophes: possessive "'s" stays lowercase, others capitalize
        case String.split(part, "'", parts: 2) do
          [before, "s"] ->
            String.capitalize(before) <> "'s"

          [before, "S"] ->
            String.capitalize(before) <> "'s"

          [before, after_apo] ->
            String.capitalize(before) <> "'" <> String.capitalize(after_apo)

          [single] ->
            String.capitalize(single)
        end
      end)
    end)
  end

  # Returns nil for nil, empty string, or whitespace-only values
  defp non_empty(nil), do: nil
  defp non_empty(val) when is_binary(val) do
    trimmed = String.trim(val)
    if trimmed == "", do: nil, else: trimmed
  end

  @species_map %{
    "bear cub" => "Cub"
  }

  defp normalize_species(nil), do: "Unknown"

  defp normalize_species(species) do
    Map.get(@species_map, String.downcase(String.trim(species)), species)
  end

  defp format_price(nil, _), do: "Not for sale"
  defp format_price(price, currency), do: "#{price} #{currency || "Bells"}"

  defp derive_source(info) do
    sources =
      1..8
      |> Enum.reduce_while([], fn i, acc ->
        case non_empty(info["availability#{i}"]) do
          nil -> {:halt, acc}
          val -> {:cont, acc ++ [{val, info["availability#{i}-note"] || ""}]}
        end
      end)
      |> Enum.reject(&tutorial_source?/1)
      |> Enum.map(fn {source, note} -> normalize_source(source, note) end)
      |> Enum.uniq()

    sources =
      if Enum.any?(sources, &(&1 == "DIY Crafting")) do
        diy_from =
          1..4
          |> Enum.reduce_while([], fn i, acc ->
            case non_empty(info["diy-availability#{i}"]) do
              nil -> {:halt, acc}
              val -> {:cont, acc ++ [val]}
            end
          end)

        case diy_from do
          [] -> sources
          froms ->
            recipe_sources = Enum.map_join(froms, ", ", &title_case/1)
            (sources -- ["DIY Crafting"]) ++ ["DIY (recipe from #{recipe_sources})"]
        end
      else
        sources
      end

    case sources do
      [] -> "Unknown"
      list -> Enum.join(list, ", ")
    end
  end

  defp tutorial_source?({source, note}) do
    downcased = String.downcase(source)
    note_down = String.downcase(note)

    (downcased == "timmy" and String.contains?(note_down, "resident services")) or
      (downcased == "tom nook" and String.contains?(note_down, "tutorial"))
  end

  @source_map %{
    "mabel" => "Able Sisters",
    "sable" => "Able Sisters",
    "label" => "Able Sisters",
    "apparel shop" => "Able Sisters",
    "timmy" => "Nook's Cranny",
    "tommy" => "Nook's Cranny",
    "kicks" => "Kicks",
    "leif" => "Leif",
    "saharah" => "Saharah",
    "redd" => "Jolly Redd's Treasure Trawler",
    "crafting" => "DIY Crafting",
    "cooking" => "Cooking"
  }

  defp normalize_source(source, _note) do
    Map.get(@source_map, String.downcase(source), title_case(source))
  end

  defp extract_recipe(info) do
    1..6
    |> Enum.reduce_while([], fn i, acc ->
      case non_empty(info["mat#{i}"]) do
        nil ->
          {:halt, acc}

        mat ->
          num = info["mat#{i}-num"] || "?"
          {:cont, acc ++ ["#{title_case(mat)} x#{num}"]}
      end
    end)
  end

  # Extract weather from location string or dedicated field
  # Fish: weather embedded in location like "Sea (raining)" → location="Sea", weather="Raining"
  # Bugs: have explicit weather field
  # Sea creatures: always underwater, no weather
  defp extract_weather(location, _weather_field, :sea), do: {location, nil}

  defp extract_weather(location, weather_field, :bug) do
    {location, non_empty(weather_field) || "Any"}
  end

  defp extract_weather(location, _weather_field, :fish) do
    case Regex.run(~r/^(.+?)\s*\(([^)]+)\)\s*$/, location) do
      [_, loc, condition] -> {String.trim(loc), title_case(String.trim(condition))}
      _ -> {location, "Any"}
    end
  end

  defp strip_page_prefix(title) do
    title
    |> String.replace(~r/^Item:/, "")
    |> String.replace(~r/\s*\(New Horizons\)\s*$/, "")
  end
end
