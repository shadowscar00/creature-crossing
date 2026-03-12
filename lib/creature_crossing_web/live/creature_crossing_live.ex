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
    %{selected: selected, bugs: bugs, fish: fish, sea: sea, hemisphere: hemisphere} =
      socket.assigns

    all_critters = bugs ++ fish ++ sea

    selected_critters =
      Enum.filter(all_critters, fn c -> MapSet.member?(selected, c["name"]) end)

    result = CreatureCrossing.Overlap.calculate(selected_critters, hemisphere)

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
  def handle_event("back_to_selection", _params, socket) do
    {:noreply, assign(socket, result: nil)}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :min_selection, @min_selection)
    assigns = assign(assigns, :selection_count, MapSet.size(assigns.selected))
    assigns = assign(assigns, :can_calculate, assigns.selection_count >= @min_selection)

    if assigns.result do
      render_results(assigns)
    else
      render_selection(assigns)
    end
  end

  defp render_selection(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto px-4 py-8">
      <h1 style="font-size: 2.5rem;" class="font-extrabold tracking-tight text-center mb-8">
        Critter Calculator
      </h1>

      <%!-- Controls row --%>
      <div style="display: flex; align-items: center; justify-content: center; gap: 6rem; margin-bottom: 2rem;">
        <%!-- Hemisphere toggle --%>
        <div style="display: flex; align-items: center; gap: 0.5rem;">
          <span class="hero-globe-americas" style="width: 1.25rem; height: 1.25rem; opacity: 0.7;"></span>
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
        </div>

        <%!-- Mode toggle --%>
        <div style="display: flex; align-items: center; gap: 0.5rem;">
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
        </div>
      </div>

      <%!-- Three category boxes side by side --%>
      <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1.5rem; margin-bottom: 2rem;">
        <.critter_box title="Bugs" critters={@bugs} selected={@selected} />
        <.critter_box title="Fish" critters={@fish} selected={@selected} />
        <.critter_box title="Diving" critters={@sea} selected={@selected} />
      </div>

      <%!-- Calculate button --%>
      <div style="text-align: center; padding-top: 1rem;">
        <button
          phx-click="calculate"
          disabled={!@can_calculate}
          class="btn btn-primary btn-lg btn-wide text-lg"
        >
          Calculate
        </button>
        <p style="margin-top: 0.75rem;" class="text-sm text-base-content/70">
          {@selection_count} selected
          {if @selection_count < @min_selection,
            do: " (need #{@min_selection - @selection_count} more)",
            else: ""}
        </p>
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
    <div class="max-w-5xl mx-auto px-4 py-8">
      <%!-- Back button --%>
      <div style="margin-bottom: 1.5rem;">
        <button phx-click="back_to_selection" class="btn btn-sm btn-ghost">
          <span class="hero-arrow-left" style="width: 1rem; height: 1rem;"></span>
          Back to selection
        </button>
      </div>

      <%!-- Result header --%>
      <div style="text-align: center; margin-bottom: 2rem;">
        <h1 style="font-size: 2.5rem;" class="font-extrabold tracking-tight mb-2">
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

      <%!-- Recalculate section --%>
      <div :if={@caught_count >= 3} style="text-align: center; padding-top: 1rem;">
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
    </div>
    """
  end

  defp critter_box(assigns) do
    ~H"""
    <div style={"border: 2px solid var(--color-neutral); border-radius: 0.75rem; overflow: hidden; display: flex; flex-direction: column; background: var(--color-base-200);"}>
      <h2 style="text-align: center; font-weight: 700; font-size: 0.95rem; padding: 0.6rem 0; background: var(--color-base-300); border-bottom: 2px solid var(--color-neutral);">
        {@title} ({length(@critters)})
      </h2>
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
          <span style="flex: 1; text-align: center; font-weight: 600; font-size: 0.875rem;">{critter["name"]}</span>
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

  defp result_card(assigns) do
    time_str =
      if assigns.result.month do
        month_num =
          assigns.result.month
          |> then(fn name ->
            Enum.find(1..12, fn m ->
              Map.get(
                %{1 => "January", 2 => "February", 3 => "March", 4 => "April",
                  5 => "May", 6 => "June", 7 => "July", 8 => "August",
                  9 => "September", 10 => "October", 11 => "November", 12 => "December"},
                m
              ) == name
            end)
          end)

        get_in(assigns.critter, [assigns.hemisphere, "times_by_month", to_string(month_num)]) ||
          "All day"
      else
        "—"
      end

    assigns = assign(assigns, :time_str, time_str)

    ~H"""
    <div
      phx-click="toggle_caught"
      phx-value-name={@critter["name"]}
      style={"border: 2px solid var(--color-neutral); border-radius: 0.75rem; padding: 1rem; cursor: pointer; text-align: center; background: var(--color-base-200); transition: opacity 0.2s;#{if @caught, do: " opacity: 0.4;", else: ""}"}
    >
      <img
        src={@critter["image_url"]}
        alt=""
        style="width: 4rem; height: 4rem; object-fit: contain; margin: 0 auto 0.5rem auto;"
        loading="lazy"
        onerror="this.style.display='none'"
      />
      <p style="font-weight: 700; font-size: 0.875rem; margin-bottom: 0.25rem;">
        {@critter["name"]}
      </p>
      <p style="font-size: 0.75rem; opacity: 0.7;">
        {@critter["location"]}
      </p>
      <p style="font-size: 0.75rem; opacity: 0.7;">
        {@critter["rarity"]}
      </p>
      <p style="font-size: 0.75rem; opacity: 0.7;">
        {@time_str}
      </p>
      <p :if={@caught} class="text-primary" style="font-weight: 700; margin-top: 0.25rem;">
        Caught!
      </p>
    </div>
    """
  end

  defp sort_by_name(critters) do
    Enum.sort_by(critters, & &1["name"])
  end
end
