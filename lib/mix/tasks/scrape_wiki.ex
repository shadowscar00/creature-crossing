defmodule Mix.Tasks.ScrapeWiki do
  @moduledoc """
  Scrapes data from Nookipedia's MediaWiki API and imports it into the local database.

  Usage:
      mix scrape_wiki            # scrape all categories
      mix scrape_wiki fish       # scrape only fish
      mix scrape_wiki villagers  # scrape only villagers
  """
  use Mix.Task

  alias CreatureCrossing.Repo
  alias CreatureCrossing.Data.{Critter, Villager, Item, HemisphereParser}
  alias CreatureCrossing.Nookipedia.WikiScraper

  @shortdoc "Scrape Nookipedia wiki and import data into local DB"

  @critter_categories %{
    fish: "Category:New Horizons fish",
    bug: "Category:New Horizons bugs",
    sea: "Category:New Horizons sea creatures"
  }

  @item_categories %{
    "furniture" => "Category:New Horizons furniture",
    "clothing" => "Category:New Horizons clothing",
    "tool" => "Category:New Horizons tools"
  }

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    categories =
      case args do
        [] -> [:fish, :bugs, :sea, :villagers, :items]
        other -> Enum.map(other, &String.to_atom/1)
      end

    if :fish in categories or :bugs in categories or :sea in categories do
      scrape_critters(categories)
    end

    if :villagers in categories, do: scrape_villagers()
    if :items in categories, do: scrape_items()

    Mix.shell().info("\nDone!")
  end

  defp scrape_critters(categories) do
    critter_types =
      Enum.flat_map(categories, fn
        :fish -> [{:fish, @critter_categories.fish}]
        :bugs -> [{:bug, @critter_categories.bug}]
        :sea -> [{:sea, @critter_categories.sea}]
        _ -> []
      end)

    for {type, wiki_category} <- critter_types do
      Mix.shell().info("\n=== Scraping #{type} ===")

      case WikiScraper.list_category_members(wiki_category) do
        {:ok, titles} ->
          total = length(titles)
          Mix.shell().info("Found #{total} #{type} pages")

          titles
          |> Enum.with_index(1)
          |> Enum.each(fn {title, idx} ->
            Mix.shell().info("[#{idx}/#{total}] #{Atom.to_string(type) |> String.capitalize()}: #{title}")

            case WikiScraper.fetch_critter(title, type) do
              {:ok, data} ->
                upsert_critter(data)

              {:error, reason} ->
                Mix.shell().error("  Failed: #{inspect(reason)}")
            end

            Process.sleep(200)
          end)

        {:error, reason} ->
          Mix.shell().error("Failed to list #{type}: #{inspect(reason)}")
      end
    end
  end

  defp scrape_villagers do
    Mix.shell().info("\n=== Scraping villagers ===")

    case WikiScraper.list_category_members("Category:New Horizons villagers") do
      {:ok, titles} ->
        total = length(titles)
        Mix.shell().info("Found #{total} villager pages")

        titles
        |> Enum.with_index(1)
        |> Enum.each(fn {title, idx} ->
          Mix.shell().info("[#{idx}/#{total}] Villager: #{title}")

          case WikiScraper.fetch_villager(title) do
            {:ok, data} ->
              upsert_villager(data)

            {:error, reason} ->
              Mix.shell().error("  Failed: #{inspect(reason)}")
          end

          Process.sleep(200)
        end)

      {:error, reason} ->
        Mix.shell().error("Failed to list villagers: #{inspect(reason)}")
    end
  end

  defp scrape_items do
    for {subcategory, wiki_category} <- @item_categories do
      Mix.shell().info("\n=== Scraping #{subcategory} ===")

      namespace = if subcategory in ["furniture", "clothing"], do: "708", else: "0"

      case WikiScraper.list_category_members(wiki_category, namespace: namespace) do
        {:ok, titles} ->
          total = length(titles)
          Mix.shell().info("Found #{total} #{subcategory} pages")

          titles
          |> Enum.with_index(1)
          |> Enum.each(fn {title, idx} ->
            Mix.shell().info("[#{idx}/#{total}] #{String.capitalize(subcategory)}: #{title}")

            case WikiScraper.fetch_item(title) do
              {:ok, data} ->
                upsert_item(subcategory, data)

              {:error, reason} ->
                Mix.shell().error("  Failed: #{inspect(reason)}")
            end

            Process.sleep(200)
          end)

        {:error, reason} ->
          Mix.shell().error("Failed to list #{subcategory}: #{inspect(reason)}")
      end
    end
  end

  defp upsert_critter(data) do
    type_str = Atom.to_string(data.type)

    north_data =
      HemisphereParser.build(data.months_north, data.time)
      |> Jason.encode!()

    south_data =
      HemisphereParser.build(data.months_south, data.time)
      |> Jason.encode!()

    attrs = %{
      type: type_str,
      name: data.name,
      location: data.location,
      weather: data.weather,
      rarity: data.rarity,
      sell_nook: data.sell_nook,
      sell_special: data.sell_special,
      time: data.time,
      months_north: data.months_north,
      months_south: data.months_south,
      north_data: north_data,
      south_data: south_data,
      shadow_size: data.shadow_size,
      speed: data.speed,
      catchphrase: data.catchphrase,
      icon_url: data.icon_url
    }

    Repo.insert!(
      Critter.changeset(%Critter{}, attrs),
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:type, :name]
    )
  end

  defp upsert_villager(data) do
    {birthday_month, birthday_day} = parse_birthday_parts(data.birthday)

    attrs = %{
      name: data.name,
      species: data.species,
      personality: data.personality,
      gender: data.gender,
      birthday: data.birthday,
      birthday_month: birthday_month,
      birthday_day: birthday_day,
      sign: data.sign,
      catchphrase: data.catchphrase,
      hobby: data.hobby,
      fav_colors: "[]",
      fav_styles: "[]",
      icon_url: data.icon_url,
      poster_url: data.poster_url,
      amiibo_url: data.amiibo_url
    }

    Repo.insert!(
      Villager.changeset(%Villager{}, attrs),
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:name]
    )
  end

  defp upsert_item(subcategory, data) do
    attrs = %{
      subcategory: subcategory,
      name: data.name,
      buy_price: data.buy_price,
      sell_price: data.sell_price,
      source: data.source,
      category: data.category,
      uses: data.uses,
      variation: data.variation,
      icon_url: data.icon_url
    }

    Repo.insert!(
      Item.changeset(%Item{}, attrs),
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:subcategory, :name]
    )
  end

  defp parse_birthday_parts(birthday_str) when is_binary(birthday_str) do
    case String.split(birthday_str, " ", parts: 2) do
      [month, day] -> {month, day}
      _ -> {birthday_str, ""}
    end
  end

  defp parse_birthday_parts(_), do: {"Unknown", ""}
end
