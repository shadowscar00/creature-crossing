defmodule CreatureCrossingWeb.DataTestLive do
  @moduledoc """
  TEMPORARY test page for verifying wiki scraper data.
  This page will NOT be pushed to main — delete after verification.
  """
  use CreatureCrossingWeb, :live_view

  alias CreatureCrossing.Nookipedia.WikiScraper

  # Items to fetch per category: {page_title, display_name_hint}
  @villagers ["Fauna", "Raymond", "Molly"]

  @fish [
    {"Piranha", "Piranha"},
    {"Blue marlin", "Blue Marlin"},
    {"Napoleonfish", "Napoleonfish"}
  ]

  @bugs [
    {"Firefly", "Firefly"},
    {"Rosalia batesi beetle", "Rosalia Batesi Beetle"},
    {"Mantis", "Mantis"}
  ]

  @sea_creatures [
    {"Chambered nautilus", "Chambered Nautilus"},
    {"Moon jellyfish", "Moon Jellyfish"},
    {"Flatworm", "Flatworm"}
  ]

  @clothing [
    {"Item:Morning coat (New Horizons)", "Morning Coat"},
    {"Item:Flashy kimono (New Horizons)", "Flashy Kimono"},
    {"Item:Space parka (New Horizons)", "Space Parka"}
  ]

  @hats [
    {"Item:Straw hat (New Horizons)", "Straw Hat"},
    {"Item:Tiara (New Horizons)", "Tiara"},
    {"Item:Samurai helmet (New Horizons)", "Samurai Helmet"}
  ]

  @furniture [
    {"Item:Lily record player (New Horizons)", "Lily Record Player"},
    {"Item:Bamboo bench (New Horizons)", "Bamboo Bench"},
    {"Item:Golden toilet (New Horizons)", "Golden Toilet"}
  ]

  @tools [
    {"Item:Colorful net (New Horizons)", "Colorful Net"},
    {"Item:Outdoorsy rod (New Horizons)", "Outdoorsy Rod"},
    {"Item:Elephant watering can (New Horizons)", "Elephant Watering Can"}
  ]

  @food [
    {"Item:Apple pie (New Horizons)", "Apple Pie"},
    {"Item:Veggie sandwich (New Horizons)", "Veggie Sandwich"},
    {"Item:Tomato curry (New Horizons)", "Tomato Curry"}
  ]

  @ingredients [
    {"Item:Potato (New Horizons)", "Potato"},
    {"Item:Cherry (New Horizons)", "Cherry"},
    {"Item:Whole-wheat flour (New Horizons)", "Whole-Wheat Flour"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        page_title: "Data Scraper Test",
        loading: true,
        categories: []
      )

    if connected?(socket) do
      send(self(), :fetch_data)
    end

    {:ok, socket}
  end

  @impl true
  def handle_info(:fetch_data, socket) do
    categories = [
      fetch_category("Villagers", @villagers, :villager),
      fetch_category("Fish", @fish, :fish),
      fetch_category("Bugs", @bugs, :bug),
      fetch_category("Sea Creatures", @sea_creatures, :sea),
      fetch_category("Clothing", @clothing, :clothing),
      fetch_category("Hats & Accessories", @hats, :hat),
      fetch_category("Furniture", @furniture, :furniture),
      fetch_category("Tools", @tools, :tool),
      fetch_category("Food (Recipes)", @food, :food),
      fetch_category("Ingredients", @ingredients, :ingredient)
    ]

    {:noreply, assign(socket, loading: false, categories: categories)}
  end

  defp fetch_category(label, items, :villager) do
    results =
      Enum.map(items, fn name ->
        case WikiScraper.fetch_villager(name) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, %{name: name, reason: reason}}
        end
      end)

    %{label: label, type: :villager, results: results}
  end

  defp fetch_category(label, items, type) when type in [:fish, :bug, :sea] do
    results =
      Enum.map(items, fn {page, _hint} ->
        case WikiScraper.fetch_critter(page, type) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, %{name: page, reason: reason}}
        end
      end)

    %{label: label, type: :critter, results: results}
  end

  defp fetch_category(label, items, type) when type in [:clothing, :hat, :furniture] do
    results =
      Enum.map(items, fn {page, _hint} ->
        # Clothing/hats may need variant in icon name — try without variant first
        case WikiScraper.fetch_item(page) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, %{name: page, reason: reason}}
        end
      end)

    %{label: label, type: :item, results: results}
  end

  defp fetch_category(label, items, :tool) do
    results =
      Enum.map(items, fn {page, _hint} ->
        case WikiScraper.fetch_item(page) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, %{name: page, reason: reason}}
        end
      end)

    %{label: label, type: :item, results: results}
  end

  defp fetch_category(label, items, :food) do
    results =
      Enum.map(items, fn {page, _hint} ->
        case WikiScraper.fetch_food(page) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, %{name: page, reason: reason}}
        end
      end)

    %{label: label, type: :food, results: results}
  end

  defp fetch_category(label, items, :ingredient) do
    results =
      Enum.map(items, fn {page, _hint} ->
        case WikiScraper.fetch_ingredient(page) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, %{name: page, reason: reason}}
        end
      end)

    %{label: label, type: :ingredient, results: results}
  end

  @impl true
  def handle_event("gallery_prev", %{"name" => name}, socket) do
    gallery = Map.get(socket.assigns[:gallery_index] || %{}, name, 0)
    new_idx = max(gallery - 1, 0)
    {:noreply, assign(socket, gallery_index: Map.put(socket.assigns[:gallery_index] || %{}, name, new_idx))}
  end

  @impl true
  def handle_event("gallery_next", %{"name" => name}, socket) do
    gallery = Map.get(socket.assigns[:gallery_index] || %{}, name, 0)
    new_idx = min(gallery + 1, 2)
    {:noreply, assign(socket, gallery_index: Map.put(socket.assigns[:gallery_index] || %{}, name, new_idx))}
  end

  @impl true
  def render(assigns) do
    assigns = assign_new(assigns, :gallery_index, fn -> %{} end)

    ~H"""
    <div class="max-w-6xl mx-auto px-4" style="padding-top: 0.5rem; padding-bottom: 2rem;">
      <h1 style="font-size: 2.5rem; margin-bottom: 0.5rem;" class="font-extrabold tracking-tight text-center">
        Wiki Scraper Test
      </h1>
      <p class="text-center text-base-content/60" style="margin-bottom: 1.5rem;">
        Temporary page — verifying scraped data from Nookipedia wiki
      </p>

      <div :if={@loading} class="text-center" style="padding: 4rem;">
        <span class="loading loading-spinner loading-lg text-primary"></span>
        <p class="text-base-content/60" style="margin-top: 1rem;">Fetching data from Nookipedia wiki...</p>
        <p class="text-base-content/40 text-sm">This may take a moment (30 API calls)</p>
      </div>

      <div :if={!@loading}>
        <div :for={category <- @categories} style="margin-bottom: 2rem;">
          <h2 style="font-size: 1.5rem; font-weight: 800; margin-bottom: 0.75rem; border-bottom: 2px solid var(--color-primary); padding-bottom: 0.25rem;"
              class="text-primary">
            {category.label}
          </h2>

          <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem;">
            <div :for={result <- category.results}>
              <%= case result do %>
                <% {:ok, data} -> %>
                  <.data_card data={data} type={category.type} gallery_index={@gallery_index} />
                <% {:error, err} -> %>
                  <.error_card error={err} />
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp data_card(%{type: :villager} = assigns) do
    idx = Map.get(assigns.gallery_index, assigns.data.name, 0)

    images = [
      %{url: assigns.data.icon_url, label: "NH Villager Icon"},
      %{url: assigns.data.poster_url, label: "Poster"},
      %{url: assigns.data.amiibo_url, label: "Amiibo Card (NA)"}
    ]

    current_image = Enum.at(images, idx)

    assigns =
      assigns
      |> assign(:idx, idx)
      |> assign(:images, images)
      |> assign(:current_image, current_image)

    ~H"""
    <div style="border: 2px solid var(--color-neutral); border-radius: 0.75rem; background: var(--color-base-200); overflow: hidden;">
      <%!-- Image gallery --%>
      <div style="position: relative; background: var(--color-base-300); padding: 0.75rem; text-align: center; min-height: 140px; display: flex; flex-direction: column; align-items: center; justify-content: center;">
        <img
          src={@current_image.url}
          alt={@current_image.label}
          style="max-height: 100px; max-width: 100px; object-fit: contain;"
          loading="lazy"
          onerror="this.src='/images/critter_placeholder.svg'"
        />
        <p style="font-size: 0.7rem; margin-top: 0.25rem; opacity: 0.6;">{@current_image.label}</p>

        <%!-- Gallery nav --%>
        <div style="display: flex; justify-content: space-between; width: 100%; position: absolute; top: 50%; transform: translateY(-50%); padding: 0 0.25rem;">
          <button
            :if={@idx > 0}
            phx-click="gallery_prev"
            phx-value-name={@data.name}
            class="btn btn-xs btn-circle btn-ghost"
            style="opacity: 0.7;"
          >
            <span class="hero-chevron-left" style="width: 1rem; height: 1rem;"></span>
          </button>
          <span :if={@idx == 0} />
          <button
            :if={@idx < 2}
            phx-click="gallery_next"
            phx-value-name={@data.name}
            class="btn btn-xs btn-circle btn-ghost"
            style="opacity: 0.7;"
          >
            <span class="hero-chevron-right" style="width: 1rem; height: 1rem;"></span>
          </button>
          <span :if={@idx == 2} />
        </div>

        <%!-- Dots --%>
        <div style="display: flex; gap: 0.25rem; justify-content: center; margin-top: 0.25rem;">
          <span :for={i <- 0..2} style={"width: 6px; height: 6px; border-radius: 50%; background: #{if i == @idx, do: "var(--color-primary)", else: "var(--color-neutral)"};"} />
        </div>
      </div>

      <%!-- Data fields --%>
      <div style="padding: 0.75rem;">
        <p style="font-weight: 700; font-size: 1rem; margin-bottom: 0.5rem; text-align: center;">
          {@data.name}
        </p>
        <div style="font-size: 0.8rem; line-height: 1.6;">
          <p><strong>Species:</strong> {@data.species}</p>
          <p><strong>Personality:</strong> {@data.personality}</p>
          <p><strong>Gender:</strong> {@data.gender}</p>
          <p><strong>Birthday:</strong> {@data.birthday}</p>
          <p><strong>Star Sign:</strong> {@data.sign}</p>
          <p><strong>Catchphrase:</strong> "{@data.catchphrase}"</p>
          <p><strong>Hobby:</strong> {@data.hobby}</p>
        </div>
      </div>
    </div>
    """
  end

  defp data_card(%{type: :critter} = assigns) do
    ~H"""
    <div style="border: 2px solid var(--color-neutral); border-radius: 0.75rem; background: var(--color-base-200); overflow: hidden;">
      <div style="background: var(--color-base-300); padding: 0.75rem; text-align: center; min-height: 100px; display: flex; align-items: center; justify-content: center;">
        <img
          src={@data.icon_url}
          alt={@data.name}
          style="max-height: 80px; max-width: 80px; object-fit: contain;"
          loading="lazy"
          onerror="this.src='/images/critter_placeholder.svg'"
        />
      </div>
      <div style="padding: 0.75rem;">
        <p style="font-weight: 700; font-size: 1rem; margin-bottom: 0.5rem; text-align: center;">
          {@data.name}
        </p>
        <div style="font-size: 0.8rem; line-height: 1.6;">
          <p :if={@data.type != :sea}><strong>Location:</strong> {@data.location}</p>
          <p :if={@data.weather}><strong>Weather:</strong> {@data.weather}</p>
          <p :if={@data.rarity}><strong>Rarity:</strong> {@data.rarity}</p>
          <p><strong>Sell (Nook):</strong> {@data.sell_nook} Bells</p>
          <p :if={@data.sell_special}><strong>Sell ({@data.sell_special_name}):</strong> {@data.sell_special} Bells</p>
          <p><strong>Time:</strong> {@data.time}</p>
          <p><strong>Months (North):</strong> {@data.months_north}</p>
          <p><strong>Months (South):</strong> {@data.months_south}</p>
          <p :if={@data.shadow_size}><strong>Shadow Size:</strong> {@data.shadow_size}</p>
          <p :if={@data.speed}><strong>Speed:</strong> {@data.speed}</p>
          <p :if={@data.catchphrase != ""} style="font-style: italic; margin-top: 0.25rem; opacity: 0.8;">"{@data.catchphrase}"</p>
        </div>
      </div>
    </div>
    """
  end

  defp data_card(%{type: :item} = assigns) do
    ~H"""
    <div style="border: 2px solid var(--color-neutral); border-radius: 0.75rem; background: var(--color-base-200); overflow: hidden;">
      <div style="background: var(--color-base-300); padding: 0.75rem; text-align: center; min-height: 100px; display: flex; align-items: center; justify-content: center;">
        <img
          src={@data.icon_url}
          alt={@data.name}
          style="max-height: 80px; max-width: 80px; object-fit: contain;"
          loading="lazy"
          onerror="this.src='/images/critter_placeholder.svg'"
        />
      </div>
      <div style="padding: 0.75rem;">
        <p style="font-weight: 700; font-size: 1rem; margin-bottom: 0.5rem; text-align: center;">
          {@data.name}
        </p>
        <div style="font-size: 0.8rem; line-height: 1.6;">
          <p><strong>Buy Price:</strong> {@data.buy_price}</p>
          <p><strong>Sell Price:</strong> {@data.sell_price}</p>
          <p><strong>Source:</strong> {@data.source}</p>
          <p :if={@data.category != "Unknown"}><strong>Category:</strong> {@data.category}</p>
          <p :if={@data[:variation]}><strong>Variant:</strong> {@data.variation}</p>
          <p :if={@data[:uses]}><strong>Durability:</strong> {@data.uses} uses</p>
        </div>
      </div>
    </div>
    """
  end

  defp data_card(%{type: :food} = assigns) do
    ~H"""
    <div style="border: 2px solid var(--color-neutral); border-radius: 0.75rem; background: var(--color-base-200); overflow: hidden;">
      <div style="background: var(--color-base-300); padding: 0.75rem; text-align: center; min-height: 100px; display: flex; align-items: center; justify-content: center;">
        <img
          src={@data.icon_url}
          alt={@data.name}
          style="max-height: 80px; max-width: 80px; object-fit: contain;"
          loading="lazy"
          onerror="this.src='/images/critter_placeholder.svg'"
        />
      </div>
      <div style="padding: 0.75rem;">
        <p style="font-weight: 700; font-size: 1rem; margin-bottom: 0.5rem; text-align: center;">
          {@data.name}
        </p>
        <div style="font-size: 0.8rem; line-height: 1.6;">
          <p><strong>Sell Price:</strong> {@data.sell_price}</p>
          <p><strong>Energy:</strong> {@data.energy} points</p>
          <div :if={@data.recipe != []}>
            <p style="margin-top: 0.25rem;"><strong>Recipe:</strong></p>
            <ul style="margin-left: 1rem; list-style: disc;">
              <li :for={ingredient <- @data.recipe}>{ingredient}</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp data_card(%{type: :ingredient} = assigns) do
    ~H"""
    <div style="border: 2px solid var(--color-neutral); border-radius: 0.75rem; background: var(--color-base-200); overflow: hidden;">
      <div style="background: var(--color-base-300); padding: 0.75rem; text-align: center; min-height: 100px; display: flex; align-items: center; justify-content: center;">
        <img
          src={@data.icon_url}
          alt={@data.name}
          style="max-height: 80px; max-width: 80px; object-fit: contain;"
          loading="lazy"
          onerror="this.src='/images/critter_placeholder.svg'"
        />
      </div>
      <div style="padding: 0.75rem;">
        <p style="font-weight: 700; font-size: 1rem; margin-bottom: 0.5rem; text-align: center;">
          {@data.name}
        </p>
        <div style="font-size: 0.8rem; line-height: 1.6;">
          <p><strong>Sell Price:</strong> {@data.sell_price}</p>
          <p><strong>Stack Size:</strong> {@data.stack}</p>
          <p><strong>Energy:</strong> {@data.energy} points</p>
        </div>
      </div>
    </div>
    """
  end

  defp error_card(assigns) do
    ~H"""
    <div style="border: 2px solid var(--color-error); border-radius: 0.75rem; background: color-mix(in oklch, var(--color-error) 10%, var(--color-base-200)); padding: 1rem;">
      <p style="font-weight: 700; color: var(--color-error);">Error</p>
      <p style="font-size: 0.8rem;">Page: {@error.name}</p>
      <p style="font-size: 0.8rem;">Reason: {inspect(@error.reason)}</p>
    </div>
    """
  end
end
