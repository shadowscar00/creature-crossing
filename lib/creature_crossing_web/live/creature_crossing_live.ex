defmodule CreatureCrossingWeb.CreatureCrossingLive do
  @moduledoc """
  Creature Crossing critter tool — cross-reference missing critters
  to find the optimal catching time.
  """
  use CreatureCrossingWeb, :live_view

  alias CreatureCrossing.Nookipedia

  @min_selection 5

  @impl true
  def mount(_params, _session, socket) do
    {:ok, bugs} = Nookipedia.list_bugs()
    {:ok, fish} = Nookipedia.list_fish()
    {:ok, sea} = Nookipedia.list_sea_creatures()

    bugs = sort_by_name(bugs)
    fish = sort_by_name(fish)
    sea = sort_by_name(sea)

    {:ok,
     assign(socket,
       page_title: "Critter Tool",
       bugs: bugs,
       fish: fish,
       sea: sea,
       selected: MapSet.new(),
       hemisphere: "north",
       mode: "missing",
       result: nil,
       caught: MapSet.new()
     )}
  end

  @impl true
  def handle_event("toggle_hemisphere", _params, socket) do
    new_hemi = if socket.assigns.hemisphere == "north", do: "south", else: "north"
    {:noreply, assign(socket, hemisphere: new_hemi)}
  end

  @impl true
  def handle_event("flip_mode", _params, socket) do
    new_mode = if socket.assigns.mode == "missing", do: "have", else: "missing"
    {:noreply, assign(socket, mode: new_mode)}
  end

  @impl true
  def handle_event("toggle_critter", %{"name" => name}, socket) do
    selected = socket.assigns.selected

    selected =
      if MapSet.member?(selected, name),
        do: MapSet.delete(selected, name),
        else: MapSet.put(selected, name)

    {:noreply, assign(socket, selected: selected)}
  end

  @impl true
  def handle_event("calculate", _params, socket) do
    %{selected: selected, bugs: bugs, fish: fish, sea: sea, hemisphere: hemisphere, mode: mode} =
      socket.assigns

    all_critters = bugs ++ fish ++ sea

    critters_to_calculate =
      case mode do
        "missing" ->
          # Selected = what you're missing, calculate overlap for those
          Enum.filter(all_critters, fn c -> MapSet.member?(selected, c["name"]) end)

        "have" ->
          # Selected = what you have, calculate overlap for the complement (what you're missing)
          Enum.reject(all_critters, fn c -> MapSet.member?(selected, c["name"]) end)
      end

    result = CreatureCrossing.Overlap.calculate(critters_to_calculate, hemisphere)

    {:noreply, assign(socket, result: result, caught: MapSet.new())}
  end

  @impl true
  def handle_event("toggle_caught", %{"name" => name}, socket) do
    caught = socket.assigns.caught

    caught =
      if MapSet.member?(caught, name),
        do: MapSet.delete(caught, name),
        else: MapSet.put(caught, name)

    {:noreply, assign(socket, caught: caught)}
  end

  @impl true
  def handle_event("recalculate", _params, socket) do
    %{result: result, caught: caught, hemisphere: hemisphere} = socket.assigns

    remaining =
      Enum.reject(result.critters, fn c -> MapSet.member?(caught, c["name"]) end)

    new_result = CreatureCrossing.Overlap.calculate(remaining, hemisphere)

    {:noreply, assign(socket, result: new_result, caught: MapSet.new())}
  end

  @impl true
  def handle_event("select_all", %{"category" => category}, socket) do
    critters =
      case category do
        "bugs" -> socket.assigns.bugs
        "fish" -> socket.assigns.fish
        "sea" -> socket.assigns.sea
      end

    names = MapSet.new(critters, & &1["name"])
    all_selected = MapSet.subset?(names, socket.assigns.selected)

    selected =
      if all_selected do
        MapSet.difference(socket.assigns.selected, names)
      else
        MapSet.union(socket.assigns.selected, names)
      end

    {:noreply, assign(socket, selected: selected)}
  end

  @impl true
  def handle_event("back_to_selection", _params, socket) do
    {:noreply, assign(socket, result: nil)}
  end

  @impl true
  def render(assigns) do
    total_critters = length(assigns.bugs) + length(assigns.fish) + length(assigns.sea)
    selection_count = MapSet.size(assigns.selected)

    # In "have" mode, we calculate on unselected critters (the complement)
    calculate_count =
      if assigns.mode == "have",
        do: total_critters - selection_count,
        else: selection_count

    assigns = assign(assigns, :min_selection, @min_selection)
    assigns = assign(assigns, :selection_count, selection_count)
    assigns = assign(assigns, :calculate_count, calculate_count)
    assigns = assign(assigns, :can_calculate, calculate_count >= @min_selection)

    if assigns.result do
      render_results(assigns)
    else
      render_selection(assigns)
    end
  end

  defp render_selection(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto px-4" style="padding-top: 0.5rem;">
      <h1 style="font-size: 2.5rem; margin-bottom: 0.25rem;" class="font-extrabold tracking-tight text-center">
        Critter Calculator
      </h1>

      <%!-- Controls row --%>
      <div style="display: flex; align-items: center; justify-content: center; gap: 6rem; margin-bottom: 0.5rem;">
        <%!-- Hemisphere toggle --%>
        <div style="display: flex; align-items: center; gap: 0.5rem;">
          <span :if={@hemisphere == "north"} class="hero-globe-americas" style="width: 1.25rem; height: 1.25rem; opacity: 0.7;"></span>
          <span class={"text-sm font-semibold #{if @hemisphere == "north", do: "text-primary", else: "text-base-content/50"}"}>
            Northern
          </span>
          <input
            type="checkbox"
            class="toggle toggle-primary toggle-sm"
            phx-click="toggle_hemisphere"
            checked={@hemisphere == "south"}
          />
          <span class={"text-sm font-semibold #{if @hemisphere == "south", do: "text-primary", else: "text-base-content/50"}"}>
            Southern
          </span>
          <span :if={@hemisphere == "south"} class="hero-globe-americas" style="width: 1.25rem; height: 1.25rem; opacity: 0.7;"></span>
        </div>

        <%!-- Mode toggle --%>
        <div style="display: flex; align-items: center; gap: 0.5rem;">
          <span :if={@mode == "missing"} class="hero-book-open" style="width: 1.25rem; height: 1.25rem; opacity: 0.7;"></span>
          <span class={"text-sm font-semibold #{if @mode == "missing", do: "text-primary", else: "text-base-content/50"}"}>
            Missing
          </span>
          <input
            type="checkbox"
            class="toggle toggle-primary toggle-sm"
            phx-click="flip_mode"
            checked={@mode == "have"}
          />
          <span class={"text-sm font-semibold #{if @mode == "have", do: "text-primary", else: "text-base-content/50"}"}>
            Have
          </span>
          <span :if={@mode == "have"} class="hero-book-open" style="width: 1.25rem; height: 1.25rem; opacity: 0.7;"></span>
        </div>
      </div>

      <%!-- Calculate button --%>
      <div style="text-align: center; margin-bottom: 0.5rem;">
        <button
          phx-click="calculate"
          disabled={!@can_calculate}
          class="btn btn-primary btn-lg btn-wide text-lg"
        >
          Calculate
        </button>
        <p style="margin-top: 0.25rem;" class="text-sm text-base-content/70">
          {@selection_count} selected
          {if @mode == "have", do: " (#{@calculate_count} missing)", else: ""}
          {if @calculate_count < @min_selection,
            do: " — need #{@min_selection - @calculate_count} more#{if @mode == "have", do: " unselected", else: ""}",
            else: ""}
        </p>
      </div>

      <%!-- Three category boxes side by side --%>
      <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1.5rem; margin-bottom: 2rem;">
        <.critter_box title="Bugs" category="bugs" critters={@bugs} selected={@selected} />
        <.critter_box title="Fish" category="fish" critters={@fish} selected={@selected} />
        <.critter_box title="Diving" category="sea" critters={@sea} selected={@selected} />
      </div>
    </div>
    """
  end

  defp render_results(assigns) do
    caught_count = MapSet.size(assigns.caught)
    remaining_count = assigns.result.critter_count - caught_count
    can_recalculate = caught_count >= 3 and remaining_count >= 5

    assigns =
      assigns
      |> assign(:caught_count, caught_count)
      |> assign(:remaining_count, remaining_count)
      |> assign(:can_recalculate, can_recalculate)
      |> assign(:uncaught_critters,
        Enum.reject(assigns.result.critters, fn c -> MapSet.member?(assigns.caught, c["name"]) end)
      )
      |> assign(:caught_critters,
        Enum.filter(assigns.result.critters, fn c -> MapSet.member?(assigns.caught, c["name"]) end)
      )

    ~H"""
    <div class="max-w-5xl mx-auto px-4" style="padding-top: 0.25rem;">
      <%!-- Back button --%>
      <div style="margin: 0; padding: 0; line-height: 1;">
        <button phx-click="back_to_selection" class="btn btn-xs btn-ghost" style="padding: 0.125rem 0.5rem;">
          <span class="hero-arrow-left" style="width: 0.875rem; height: 0.875rem;"></span>
          Back to selection
        </button>
      </div>

      <%!-- Result header --%>
      <div style="text-align: center; margin-bottom: 0.75rem; margin-top: 0; padding-top: 0;">
        <h1 style="font-size: 2.5rem; margin: 0;" class="font-extrabold tracking-tight">
          {if @result.month, do: @result.month, else: "No Overlap"}
        </h1>
        <p :if={@result.month} style="font-size: 1.25rem;" class="text-primary font-bold">
          {@result.time_range}
        </p>
        <p style="margin-top: 0.5rem;" class="text-base-content/70">
          {@result.critter_count} critters catchable
          {if @caught_count > 0, do: " (#{@caught_count} caught)", else: ""}
        </p>
      </div>

      <%!-- Recalculate section --%>
      <div :if={@caught_count >= 3} style="text-align: center; margin-bottom: 1.5rem;">
        <button
          :if={@can_recalculate}
          phx-click="recalculate"
          class="btn btn-primary btn-lg btn-wide text-lg"
        >
          Recalculate!
        </button>
        <p :if={!@can_recalculate} class="text-base-content/70">
          Not enough critters remaining to recalculate (need at least 5)
        </p>
      </div>

      <%!-- Critter grid — uncaught first, then caught --%>
      <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: 1rem; margin-bottom: 2rem;">
        <.result_card
          :for={critter <- @uncaught_critters}
          critter={critter}
          caught={false}
          hemisphere={@hemisphere}
          result={@result}
        />
        <.result_card
          :for={critter <- @caught_critters}
          critter={critter}
          caught={true}
          hemisphere={@hemisphere}
          result={@result}
        />
      </div>
    </div>
    """
  end

  defp critter_box(assigns) do
    all_names = MapSet.new(assigns.critters, & &1["name"])
    all_selected = MapSet.subset?(all_names, assigns.selected)
    selected_count = assigns.critters |> Enum.count(fn c -> MapSet.member?(assigns.selected, c["name"]) end)
    assigns = assigns |> assign(:all_selected, all_selected) |> assign(:selected_count, selected_count)

    ~H"""
    <div style={"border: 2px solid var(--color-neutral); border-radius: 0.75rem; overflow: hidden; display: flex; flex-direction: column; background: var(--color-base-200);"}>
      <div style="display: flex; align-items: center; justify-content: space-between; padding: 0.4rem 0.75rem; background: var(--color-base-300); border-bottom: 2px solid var(--color-neutral);">
        <span style="font-weight: 700; font-size: 0.95rem;">{@title} ({@selected_count}/{length(@critters)})</span>
        <button
          phx-click="select_all"
          phx-value-category={@category}
          class="btn btn-xs btn-ghost"
          style="font-size: 0.65rem;"
        >
          {if @all_selected, do: "Deselect All", else: "Select All"}
        </button>
      </div>
      <ul style="overflow-y: auto; height: 22rem;">
        <li
          :for={critter <- @critters}
          phx-click="toggle_critter"
          phx-value-name={critter["name"]}
          style={"display: flex; align-items: center; padding: 0.5rem 0.75rem; cursor: pointer; border-bottom: 1px solid color-mix(in oklch, var(--color-neutral) 25%, transparent);#{if MapSet.member?(@selected, critter["name"]), do: " background: color-mix(in oklch, var(--color-primary) 20%, transparent);", else: ""}"}
        >
          <img
            src={critter["image_url"]}
            alt=""
            style="width: 2.25rem; height: 2.25rem; object-fit: contain; flex-shrink: 0;"
            loading="lazy"
            onerror="this.style.display='none'"
          />
          <span style="flex: 1; text-align: center; font-weight: 600; font-size: 0.875rem;">
            {critter["name"]}
            <span :if={weather_notable?(critter["weather"])} style="font-size: 0.6rem; font-weight: 400; opacity: 0.6; display: block; margin-top: -0.125rem;">
              {critter["weather"]}
            </span>
          </span>
          <span
            :if={MapSet.member?(@selected, critter["name"])}
            class="text-primary"
            style="font-weight: 700; flex-shrink: 0;"
          >
            ✓
          </span>
          <span
            :if={!MapSet.member?(@selected, critter["name"])}
            style="width: 1rem; flex-shrink: 0;"
          />
        </li>
      </ul>
    </div>
    """
  end

  @month_name_to_num %{
    "January" => 1, "February" => 2, "March" => 3, "April" => 4,
    "May" => 5, "June" => 6, "July" => 7, "August" => 8,
    "September" => 9, "October" => 10, "November" => 11, "December" => 12
  }

  defp result_card(assigns) do
    time_str =
      if assigns.result.month do
        month_num = @month_name_to_num[assigns.result.month]

        get_in(assigns.critter, [assigns.hemisphere, "times_by_month", to_string(month_num)]) ||
          "All day"
      else
        "—"
      end

    critter_type = assigns.critter["critter_type"]

    assigns =
      assigns
      |> assign(:time_str, time_str)
      |> assign(:weather, assigns.critter["weather"] || "Any")
      |> assign(:shadow_size, if(critter_type == "bug", do: "N/A", else: assigns.critter["shadow_size"] || "N/A"))
      |> assign(:speed, if(critter_type == "sea", do: assigns.critter["speed"] || "N/A", else: "N/A"))

    ~H"""
    <div
      phx-click="toggle_caught"
      phx-value-name={@critter["name"]}
      style={"border: 2px solid var(--color-neutral); border-radius: 0.75rem; padding: 1rem; cursor: pointer; background: var(--color-base-200); transition: opacity 0.2s;#{if @caught, do: " opacity: 0.4;", else: ""}"}
    >
      <img
        src={@critter["image_url"]}
        alt=""
        style="width: 4rem; height: 4rem; object-fit: contain; margin: 0 auto 0.5rem auto; display: block;"
        loading="lazy"
        onerror="this.style.display='none'"
      />
      <p style="font-weight: 700; font-size: 0.9rem; margin-bottom: 0.5rem; text-align: center;">
        {@critter["name"]}
      </p>
      <div style="font-size: 0.75rem; opacity: 0.7; text-align: left;">
        <p><strong>Location:</strong> {@critter["location"]}</p>
        <p :if={@critter["rarity"]}><strong>Rarity:</strong> {@critter["rarity"]}</p>
        <p><strong>Time:</strong> {@time_str}</p>
        <p :if={weather_notable?(@critter["weather"])}><strong>Weather:</strong> {@weather}</p>
        <p :if={@shadow_size != "N/A"}><strong>Size:</strong> {@shadow_size}</p>
        <p :if={@speed != "N/A"}><strong>Speed:</strong> {@speed}</p>
      </div>
      <p :if={@caught} class="text-primary" style="font-weight: 700; margin-top: 0.5rem; text-align: center;">
        Caught!
      </p>
    </div>
    """
  end

  defp sort_by_name(critters) do
    Enum.sort_by(critters, & &1["name"])
  end

  defp weather_notable?(nil), do: false
  defp weather_notable?(w) do
    downcased = String.downcase(w)
    String.contains?(downcased, "rain") or String.contains?(downcased, "snow")
  end
end
