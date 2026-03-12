defmodule CreatureCrossingWeb.MatchGameLive do
  @moduledoc """
  Memory match card game using Animal Crossing imagery.

  10 levels with increasing card counts (6 per level).
  Cards sourced from villagers, critters, and items.
  AC-themed card backs change each level.
  """
  use CreatureCrossingWeb, :live_view

  alias CreatureCrossing.Nookipedia

  @cards_per_level 6
  @max_level 10
  @flip_back_delay 1000

  @card_backs [
    %{name: "Leaf", emoji: "🍃"},
    %{name: "Bell Bag", emoji: "💰"},
    %{name: "Fossil", emoji: "🦴"},
    %{name: "Star", emoji: "⭐"},
    %{name: "Balloon", emoji: "🎈"},
    %{name: "Music Note", emoji: "🎵"},
    %{name: "Flower", emoji: "🌸"},
    %{name: "Shell", emoji: "🐚"},
    %{name: "Fish", emoji: "🐟"},
    %{name: "Bug", emoji: "🦋"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    # Gather all possible card sources
    {:ok, villagers} = Nookipedia.list_villagers()
    {:ok, bugs} = Nookipedia.list_bugs()
    {:ok, fish} = Nookipedia.list_fish()
    {:ok, sea} = Nookipedia.list_sea_creatures()
    {:ok, furniture} = Nookipedia.list_items("furniture")
    {:ok, clothing} = Nookipedia.list_items("clothing")

    all_sources =
      Enum.map(villagers, fn v -> %{name: v["name"], image_url: v["image_url"]} end) ++
        Enum.map(bugs, fn c -> %{name: c["name"], image_url: c["image_url"]} end) ++
        Enum.map(fish, fn c -> %{name: c["name"], image_url: c["image_url"]} end) ++
        Enum.map(sea, fn c -> %{name: c["name"], image_url: c["image_url"]} end) ++
        Enum.map(furniture, fn i -> %{name: i["name"], image_url: i["image_url"]} end) ++
        Enum.map(clothing, fn i -> %{name: i["name"], image_url: i["image_url"]} end)

    socket =
      assign(socket,
        page_title: "Match Game",
        all_sources: all_sources,
        max_level: @max_level
      )

    {:ok, start_level(socket, 1)}
  end

  defp start_level(socket, level) do
    pairs_count = div(level * @cards_per_level, 2)

    # Pick random items for pairs
    selected =
      socket.assigns.all_sources
      |> Enum.shuffle()
      |> Enum.take(pairs_count)

    # Create pairs and shuffle
    cards =
      selected
      |> Enum.flat_map(fn item ->
        pair_id = System.unique_integer([:positive])

        [
          %{id: System.unique_integer([:positive]), pair_id: pair_id, name: item.name, image_url: item.image_url},
          %{id: System.unique_integer([:positive]), pair_id: pair_id, name: item.name, image_url: item.image_url}
        ]
      end)
      |> Enum.shuffle()

    card_back = Enum.at(@card_backs, rem(level - 1, length(@card_backs)))

    assign(socket,
      level: level,
      cards: cards,
      flipped: [],
      matched: MapSet.new(),
      card_back: card_back,
      moves: 0,
      phase: :playing
    )
  end

  # --- Events ---

  @impl true
  def handle_event("flip", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    %{flipped: flipped, matched: matched, phase: phase} = socket.assigns

    # Ignore if: already matched, already flipped, checking phase, or already 2 flipped
    already_matched = MapSet.member?(matched, id)
    already_flipped = id in flipped
    checking = phase == :checking

    if already_matched || already_flipped || checking || length(flipped) >= 2 do
      {:noreply, socket}
    else
      new_flipped = flipped ++ [id]

      if length(new_flipped) == 2 do
        # Check for match
        [first_id, second_id] = new_flipped
        first_card = Enum.find(socket.assigns.cards, &(&1.id == first_id))
        second_card = Enum.find(socket.assigns.cards, &(&1.id == second_id))

        if first_card.pair_id == second_card.pair_id do
          # Match found!
          new_matched = matched |> MapSet.put(first_id) |> MapSet.put(second_id)
          all_matched = MapSet.size(new_matched) == length(socket.assigns.cards)

          socket =
            assign(socket,
              flipped: [],
              matched: new_matched,
              moves: socket.assigns.moves + 1,
              phase: if(all_matched, do: :complete, else: :playing)
            )

          {:noreply, socket}
        else
          # No match — schedule flip back
          Process.send_after(self(), :flip_back, @flip_back_delay)

          {:noreply,
           assign(socket,
             flipped: new_flipped,
             moves: socket.assigns.moves + 1,
             phase: :checking
           )}
        end
      else
        {:noreply, assign(socket, flipped: new_flipped)}
      end
    end
  end

  @impl true
  def handle_event("next_level", _params, socket) do
    next = min(socket.assigns.level + 1, @max_level)
    {:noreply, start_level(socket, next)}
  end

  @impl true
  def handle_event("restart_level", _params, socket) do
    {:noreply, start_level(socket, socket.assigns.level)}
  end

  @impl true
  def handle_event("back_to_level_1", _params, socket) do
    {:noreply, start_level(socket, 1)}
  end

  @impl true
  def handle_info(:flip_back, socket) do
    {:noreply, assign(socket, flipped: [], phase: :playing)}
  end

  # --- Render ---

  @impl true
  def render(assigns) do
    total_pairs = div(length(assigns.cards), 2)
    matched_pairs = div(MapSet.size(assigns.matched), 2)
    cols = grid_cols(length(assigns.cards))

    assigns =
      assigns
      |> assign(:total_pairs, total_pairs)
      |> assign(:matched_pairs, matched_pairs)
      |> assign(:cols, cols)

    ~H"""
    <div class="max-w-6xl mx-auto px-4" style="padding-top: 0.25rem;">
      <%!-- Header --%>
      <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.5rem;">
        <div>
          <button phx-click="back_to_level_1" class="btn btn-sm btn-ghost">
            <span class="hero-arrow-path" style="width: 1rem; height: 1rem;"></span>
            Restart
          </button>
        </div>
        <h1 style="font-size: 2rem;" class="font-extrabold tracking-tight">
          Match Game
        </h1>
        <div style="text-align: right; font-size: 0.875rem;">
          <p class="font-bold text-primary">Level {@level}/{@max_level}</p>
          <p style="opacity: 0.7;">{@matched_pairs}/{@total_pairs} pairs · {@moves} moves</p>
        </div>
      </div>

      <%!-- Level complete overlay --%>
      <div :if={@phase == :complete} style="text-align: center; margin-bottom: 1rem; padding: 1rem; border-radius: 0.75rem; background: color-mix(in oklch, var(--color-success) 15%, transparent);">
        <p style="font-size: 1.5rem; font-weight: 800; color: var(--color-success); margin-bottom: 0.25rem;">
          Level {@level} Complete!
        </p>
        <p style="opacity: 0.7; margin-bottom: 0.75rem;">
          Finished in {@moves} moves
        </p>
        <button :if={@level < @max_level} phx-click="next_level" class="btn btn-primary btn-lg">
          Next Level
        </button>
        <div :if={@level == @max_level}>
          <p style="font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem;">You beat all 10 levels!</p>
          <button phx-click="back_to_level_1" class="btn btn-primary btn-lg">
            Play Again
          </button>
        </div>
      </div>

      <%!-- Card grid --%>
      <div style="display: flex; flex-wrap: wrap; gap: 0.375rem; justify-content: center; margin-bottom: 1rem;">
        <.card
          :for={card <- @cards}
          card={card}
          flipped={card.id in @flipped}
          matched={MapSet.member?(@matched, card.id)}
          card_back={@card_back}
        />
      </div>
    </div>
    """
  end

  defp card(assigns) do
    face_up = assigns.flipped || assigns.matched

    assigns = assign(assigns, :face_up, face_up)

    ~H"""
    <div
      phx-click="flip"
      phx-value-id={@card.id}
      style={"width: 5rem; height: 6.5rem; border-radius: 0.5rem; cursor: #{if @face_up, do: "default", else: "pointer"}; perspective: 600px;"}
    >
      <div style={"position: relative; width: 100%; height: 100%; transition: transform 0.4s; transform-style: preserve-3d;#{if @face_up, do: " transform: rotateY(180deg);", else: ""}"}>
        <%!-- Card back --%>
        <div style={"position: absolute; inset: 0; backface-visibility: hidden; border-radius: 0.5rem; border: 2px solid var(--color-neutral); background: var(--color-primary); display: flex; align-items: center; justify-content: center; flex-direction: column;"}>
          <span style="font-size: 1.25rem;">{@card_back.emoji}</span>
          <span style="font-size: 0.5rem; color: var(--color-primary-content); opacity: 0.8; margin-top: 0.125rem;">{@card_back.name}</span>
        </div>

        <%!-- Card front --%>
        <div style={"position: absolute; inset: 0; backface-visibility: hidden; transform: rotateY(180deg); border-radius: 0.5rem; border: 2px solid #{if @matched, do: "var(--color-success)", else: "var(--color-neutral)"}; background: #{if @matched, do: "color-mix(in oklch, var(--color-success) 10%, var(--color-base-200))", else: "var(--color-base-200)"}; display: flex; align-items: center; justify-content: center; flex-direction: column; padding: 0.25rem;"}>
          <img
            src={@card.image_url}
            alt=""
            style="width: 2rem; height: 2rem; object-fit: contain;"
            loading="lazy"
            onerror="this.style.display='none'"
          />
          <p style="font-size: 0.6rem; font-weight: 600; text-align: center; margin-top: 0.25rem; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 100%;">
            {@card.name}
          </p>
        </div>
      </div>
    </div>
    """
  end

  # Choose grid columns based on card count
  defp grid_cols(count) when count <= 6, do: 3
  defp grid_cols(count) when count <= 12, do: 4
  defp grid_cols(count) when count <= 18, do: 6
  defp grid_cols(count) when count <= 30, do: 6
  defp grid_cols(count) when count <= 48, do: 8
  defp grid_cols(_count), do: 10
end
