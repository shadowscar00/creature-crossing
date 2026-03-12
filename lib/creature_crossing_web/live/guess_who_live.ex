defmodule CreatureCrossingWeb.GuessWhoLive do
  @moduledoc """
  Guess Who game using Animal Crossing NH villagers.

  Flow:
  1. Fetch villagers, randomly select 24 for the board
  2. Show 3 random choices from the 24 for player to pick their secret villager
  3. Player picks 1 — game begins
  4. Player clicks villagers on the board to eliminate them (grey out)
  5. Player can start a new game at any time
  """
  use CreatureCrossingWeb, :live_view

  alias CreatureCrossing.Nookipedia

  @board_size 24

  @impl true
  def mount(_params, _session, socket) do
    {:ok, villagers} = Nookipedia.list_villagers()
    socket = assign(socket, page_title: "Guess Who", all_villagers: villagers)
    {:ok, new_game(socket)}
  end

  defp new_game(socket) do
    board = socket.assigns.all_villagers |> Enum.shuffle() |> Enum.take(@board_size)
    choices = board |> Enum.shuffle() |> Enum.take(3)

    assign(socket,
      board: board,
      choices: choices,
      secret: nil,
      eliminated: MapSet.new(),
      phase: :picking
    )
  end

  @impl true
  def handle_event("pick_secret", %{"name" => name}, socket) do
    {:noreply, assign(socket, secret: name, phase: :playing)}
  end

  @impl true
  def handle_event("toggle_eliminate", %{"name" => name}, socket) do
    # Don't allow eliminating the secret villager
    if name == socket.assigns.secret do
      {:noreply, socket}
    else
      eliminated = socket.assigns.eliminated

      eliminated =
        if MapSet.member?(eliminated, name),
          do: MapSet.delete(eliminated, name),
          else: MapSet.put(eliminated, name)

      {:noreply, assign(socket, eliminated: eliminated)}
    end
  end

  @impl true
  def handle_event("new_game", _params, socket) do
    {:noreply, new_game(socket)}
  end

  @impl true
  def render(assigns) do
    case assigns.phase do
      :picking -> render_picking(assigns)
      :playing -> render_playing(assigns)
    end
  end

  defp render_picking(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4" style="padding-top: 0.5rem;">
      <h1 style="font-size: 2.5rem; margin-bottom: 0.25rem;" class="font-extrabold tracking-tight text-center">
        Guess Who
      </h1>
      <p style="margin-bottom: 1.5rem;" class="text-center text-base-content/70">
        Pick your secret villager!
      </p>

      <div style="display: flex; justify-content: center; gap: 2rem;">
        <div
          :for={villager <- @choices}
          phx-click="pick_secret"
          phx-value-name={villager["name"]}
          style="border: 2px solid var(--color-neutral); border-radius: 0.75rem; padding: 1.5rem; cursor: pointer; background: var(--color-base-200); text-align: center; width: 10rem; transition: transform 0.15s;"
          class="hover:scale-105"
        >
          <img
            src={villager["image_url"]}
            alt=""
            style="width: 5rem; height: 5rem; object-fit: contain; margin: 0 auto 0.75rem auto; display: block;"
            loading="lazy"
            onerror="this.style.display='none'"
          />
          <p style="font-weight: 700; font-size: 1rem;">{villager["name"]}</p>
          <p style="font-size: 0.75rem; opacity: 0.7; margin-top: 0.25rem;">
            {villager["species"]} · {villager["personality"]}
          </p>
        </div>
      </div>
    </div>
    """
  end

  defp render_playing(assigns) do
    remaining = @board_size - MapSet.size(assigns.eliminated)
    assigns = assign(assigns, :remaining, remaining)

    ~H"""
    <div class="max-w-5xl mx-auto px-4" style="padding-top: 0.25rem;">
      <%!-- Header row --%>
      <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.5rem;">
        <button phx-click="new_game" class="btn btn-sm btn-ghost">
          <span class="hero-arrow-path" style="width: 1rem; height: 1rem;"></span>
          New Game
        </button>
        <h1 style="font-size: 2rem;" class="font-extrabold tracking-tight">Guess Who</h1>
        <div style="font-size: 0.875rem; text-align: right;">
          <p class="font-bold text-primary">{@remaining} remaining</p>
        </div>
      </div>

      <%!-- Secret villager banner --%>
      <div style="text-align: center; margin-bottom: 0.75rem; padding: 0.5rem; border-radius: 0.5rem; background: color-mix(in oklch, var(--color-primary) 15%, transparent);">
        <span style="font-size: 0.875rem; font-weight: 600;">Your secret: </span>
        <span class="text-primary" style="font-weight: 700;">{@secret}</span>
      </div>

      <%!-- 6x4 board grid --%>
      <div style="display: grid; grid-template-columns: repeat(6, 1fr); gap: 0.75rem;">
        <div
          :for={villager <- @board}
          phx-click="toggle_eliminate"
          phx-value-name={villager["name"]}
          style={"border: 2px solid #{if villager["name"] == @secret, do: "var(--color-primary)", else: "var(--color-neutral)"}; border-radius: 0.75rem; padding: 0.5rem; cursor: pointer; background: var(--color-base-200); text-align: center; transition: opacity 0.2s;#{if MapSet.member?(@eliminated, villager["name"]), do: " opacity: 0.2;", else: ""}"}
        >
          <img
            src={villager["image_url"]}
            alt=""
            style="width: 3.5rem; height: 3.5rem; object-fit: contain; margin: 0 auto 0.25rem auto; display: block;"
            loading="lazy"
            onerror="this.style.display='none'"
          />
          <p style="font-weight: 600; font-size: 0.75rem; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
            {villager["name"]}
          </p>
        </div>
      </div>
    </div>
    """
  end
end
