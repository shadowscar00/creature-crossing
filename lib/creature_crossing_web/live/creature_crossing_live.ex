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
       active_tab: "bugs"
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
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  @impl true
  def handle_event("calculate", _params, socket) do
    # Will be implemented in 2-2
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :min_selection, @min_selection)
    assigns = assign(assigns, :selection_count, MapSet.size(assigns.selected))
    assigns = assign(assigns, :can_calculate, assigns.selection_count >= @min_selection)

    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-6">
      <h1 class="text-3xl font-extrabold tracking-tight text-center mb-6">
        Critter Tool
      </h1>

      <%!-- Controls row --%>
      <div class="flex flex-wrap items-center justify-between gap-3 mb-4">
        <%!-- Hemisphere toggle --%>
        <button
          phx-click="toggle_hemisphere"
          class="btn btn-sm btn-outline"
        >
          {if @hemisphere == "north", do: "🌐 Northern", else: "🌐 Southern"}
        </button>

        <%!-- Mode flip button --%>
        <button
          phx-click="flip_mode"
          class="btn btn-sm btn-outline"
        >
          {if @mode == "missing", do: "🔄 I'm missing these", else: "🔄 I have these"}
        </button>
      </div>

      <%!-- Tab buttons --%>
      <div role="tablist" class="tabs tabs-boxed mb-4">
        <button
          role="tab"
          phx-click="switch_tab"
          phx-value-tab="bugs"
          class={"tab #{if @active_tab == "bugs", do: "tab-active"}"}
        >
          Bugs ({length(@bugs)})
        </button>
        <button
          role="tab"
          phx-click="switch_tab"
          phx-value-tab="fish"
          class={"tab #{if @active_tab == "fish", do: "tab-active"}"}
        >
          Fish ({length(@fish)})
        </button>
        <button
          role="tab"
          phx-click="switch_tab"
          phx-value-tab="sea"
          class={"tab #{if @active_tab == "sea", do: "tab-active"}"}
        >
          Diving ({length(@sea)})
        </button>
      </div>

      <%!-- Critter list --%>
      <div class="h-96 overflow-y-auto border border-base-300 rounded-xl bg-base-100 p-2">
        <.critter_list
          critters={active_critters(assigns)}
          selected={@selected}
        />
      </div>

      <%!-- Selection count and calculate button --%>
      <div class="flex items-center justify-between mt-4">
        <span class="text-sm text-base-content/70">
          {@selection_count} selected
          {if @selection_count < @min_selection,
            do: " (need #{@min_selection - @selection_count} more)",
            else: ""}
        </span>
        <button
          phx-click="calculate"
          disabled={!@can_calculate}
          class="btn btn-primary"
        >
          Calculate
        </button>
      </div>
    </div>
    """
  end

  defp critter_list(assigns) do
    ~H"""
    <ul class="space-y-1">
      <li
        :for={critter <- @critters}
        phx-click="toggle_critter"
        phx-value-name={critter["name"]}
        class={[
          "flex items-center gap-3 px-3 py-2 rounded-lg cursor-pointer transition-colors",
          if(MapSet.member?(@selected, critter["name"]),
            do: "bg-primary/20 ring-1 ring-primary",
            else: "hover:bg-base-200"
          )
        ]}
      >
        <img
          src={critter["image_url"]}
          alt={critter["name"]}
          class="w-10 h-10 object-contain"
          loading="lazy"
        />
        <span class="font-semibold text-sm">{critter["name"]}</span>
        <span
          :if={MapSet.member?(@selected, critter["name"])}
          class="ml-auto text-primary font-bold"
        >
          ✓
        </span>
      </li>
    </ul>
    """
  end

  defp active_critters(%{active_tab: "bugs"} = assigns), do: assigns.bugs
  defp active_critters(%{active_tab: "fish"} = assigns), do: assigns.fish
  defp active_critters(%{active_tab: "sea"} = assigns), do: assigns.sea

  defp sort_by_name(critters) do
    Enum.sort_by(critters, & &1["name"])
  end
end
