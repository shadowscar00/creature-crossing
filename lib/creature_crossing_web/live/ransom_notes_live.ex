defmodule CreatureCrossingWeb.RansomNotesLive do
  @moduledoc """
  Ransom Notes — AC-themed single-player word puzzle game.

  Flow:
  1. Show intro screen with game explanation
  2. Each round: display a prompt and ~50 word tiles
  3. Player arranges tiles on NL stationery (7 lines)
  4. Submit letter for judging by Mercury API
  5. Show relevance + creativity scores with commentary
  6. After 10 rounds, show final score summary
  """
  use CreatureCrossingWeb, :live_view

  alias CreatureCrossing.RansomNotes.WordPool

  @rounds_per_game 10
  @tiles_per_round 50
  @lines_on_stationery 7

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        page_title: "Ransom Notes",
        phase: :intro,
        round: 1,
        max_rounds: @rounds_per_game,
        prompt: nil,
        available_tiles: [],
        placed_tiles: init_placed_tiles(),
        selected_tile: nil,
        scores: [],
        total_score: 0,
        judging_error: nil
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-6 p-4">
      <%= case @phase do %>
        <% :intro -> %>
          <.render_intro />
        <% :playing -> %>
          <.render_playing
            prompt={@prompt}
            round={@round}
            max_rounds={@max_rounds}
            available_tiles={@available_tiles}
            placed_tiles={@placed_tiles}
            selected_tile={@selected_tile}
          />
        <% :judging -> %>
          <.render_judging prompt={@prompt} round={@round} />
        <% :round_result -> %>
          <.render_round_result
            round={@round}
            max_rounds={@max_rounds}
            scores={@scores}
            total_score={@total_score}
          />
        <% :game_over -> %>
          <.render_game_over scores={@scores} total_score={@total_score} max_rounds={@max_rounds} />
      <% end %>
    </div>
    """
  end

  # -- Phase renderers --

  defp render_intro(assigns) do
    ~H"""
    <div class="text-center max-w-lg mt-12">
      <h1 class="text-4xl font-extrabold mb-4">Ransom Notes</h1>
      <p class="text-lg opacity-80 mb-2">
        The Animal Crossing Letter-Writing Game
      </p>
      <div class="text-left bg-base-200 rounded-xl p-6 mb-6 text-sm leading-relaxed">
        <p class="mb-3">
          Each round, you'll get a <strong>prompt</strong> and <strong>50 random word tiles</strong>.
        </p>
        <p class="mb-3">
          Arrange your words on the stationery to write the best letter you can.
          Use suffix tiles like <strong>-s</strong>, <strong>-ing</strong>, and <strong>-ed</strong>
          to modify words.
        </p>
        <p class="mb-3">
          Your letter will be judged on <strong>Relevance</strong> (how well it addresses the prompt)
          and <strong>Creativity</strong> (how clever or funny it is).
        </p>
        <p>
          <strong>10 rounds</strong>. Max score: <strong>200</strong>. Good luck!
        </p>
      </div>
      <button phx-click="start_game" class="btn btn-primary btn-lg">
        Start Game
      </button>
    </div>
    """
  end

  defp render_playing(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-4 w-full max-w-3xl">
      <%!-- Prompt --%>
      <div class="text-center">
        <p class="text-sm opacity-60 mb-1">Round {@round} of {@max_rounds}</p>
        <p class="text-xl font-bold">{@prompt}</p>
      </div>

      <%!-- Stationery --%>
      <div class="relative bg-amber-50 border-8 border-amber-900/20 rounded-lg w-full"
           style="aspect-ratio: 4/3;">
        <div
          :for={line_idx <- 0..6}
          id={"line-#{line_idx}"}
          phx-click="line_clicked"
          phx-value-line={line_idx}
          class="absolute left-8 right-8 flex flex-wrap gap-1 items-end cursor-pointer hover:bg-primary/5 transition-colors"
          style={"bottom: #{8 + (6 - line_idx) * 12.5}%; height: 10%; border-bottom: 1px solid rgba(0,0,0,0.15);"}
        >
          <span
            :for={tile <- Map.get(@placed_tiles, line_idx, [])}
            phx-click="tile_removed"
            phx-value-id={tile.id}
            class="inline-block px-2 py-0.5 bg-base-100 border border-base-300 rounded text-sm font-mono cursor-pointer hover:bg-error/20 hover:border-error transition-colors"
          >
            {tile.word}
          </span>
        </div>
      </div>

      <%!-- Available tiles --%>
      <div class="flex flex-wrap gap-2 justify-center w-full">
        <span
          :for={tile <- @available_tiles}
          phx-click="tile_selected"
          phx-value-id={tile.id}
          class={[
            "inline-block px-2 py-1 border rounded text-sm font-mono cursor-pointer transition-all",
            if(@selected_tile && @selected_tile.id == tile.id,
              do: "bg-primary text-primary-content border-primary scale-110",
              else: "bg-base-100 border-base-300 hover:bg-primary/10 hover:border-primary"
            )
          ]}
        >
          {tile.word}
        </span>
      </div>

      <%!-- Submit --%>
      <button
        phx-click="submit_letter"
        class="btn btn-primary btn-lg"
        disabled={all_lines_empty?(@placed_tiles)}
      >
        Send Letter
      </button>
    </div>
    """
  end

  defp render_judging(assigns) do
    ~H"""
    <div class="text-center mt-20">
      <span class="loading loading-spinner loading-lg text-primary"></span>
      <p class="mt-4 text-lg opacity-70">Isabelle is reading your letter...</p>
      <p class="text-sm opacity-50">Round {@round}</p>
    </div>
    """
  end

  defp render_round_result(assigns) do
    latest = List.first(assigns.scores)
    assigns = assign(assigns, :latest, latest)

    ~H"""
    <div class="text-center max-w-lg mt-8">
      <h2 class="text-2xl font-bold mb-4">Round {@round} Results</h2>

      <div class="flex justify-center gap-8 mb-4">
        <div class="text-center">
          <p class="text-sm opacity-60">Relevance</p>
          <p class="text-4xl font-extrabold">{@latest.relevance}<span class="text-lg opacity-50">/10</span></p>
        </div>
        <div class="text-center">
          <p class="text-sm opacity-60">Creativity</p>
          <p class="text-4xl font-extrabold">{@latest.creativity}<span class="text-lg opacity-50">/10</span></p>
        </div>
      </div>

      <div class="bg-base-200 rounded-xl p-4 mb-4 italic text-sm">
        "{@latest.commentary}"
      </div>

      <p class="text-lg mb-6">
        Running total: <strong>{@total_score}</strong> / {@round * 20}
      </p>

      <%= if @round < @max_rounds do %>
        <button phx-click="next_round" class="btn btn-primary btn-lg">
          Next Round
        </button>
      <% else %>
        <button phx-click="show_results" class="btn btn-primary btn-lg">
          See Final Results
        </button>
      <% end %>
    </div>
    """
  end

  defp render_game_over(assigns) do
    max_possible = assigns.max_rounds * 20
    rank = rank_title(assigns.total_score, max_possible)
    assigns = assign(assigns, :max_possible, max_possible) |> assign(:rank, rank)

    ~H"""
    <div class="text-center max-w-lg mt-8">
      <h2 class="text-3xl font-extrabold mb-2">Game Over!</h2>
      <p class="text-xl mb-1">Final Score: <strong>{@total_score}</strong> / {@max_possible}</p>
      <p class="text-lg text-primary font-bold mb-6">{@rank}</p>

      <div class="overflow-x-auto mb-6">
        <table class="table table-sm w-full">
          <thead>
            <tr>
              <th>Round</th>
              <th>Relevance</th>
              <th>Creativity</th>
              <th>Total</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={score <- Enum.reverse(@scores)}>
              <td>{score.round}</td>
              <td>{score.relevance}/10</td>
              <td>{score.creativity}/10</td>
              <td>{score.relevance + score.creativity}/20</td>
            </tr>
          </tbody>
        </table>
      </div>

      <button phx-click="play_again" class="btn btn-primary btn-lg">
        Play Again
      </button>
    </div>
    """
  end

  # -- Events --

  @impl true
  def handle_event("start_game", _params, socket) do
    {:noreply, start_round(socket)}
  end

  def handle_event("tile_selected", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    tile = Enum.find(socket.assigns.available_tiles, &(&1.id == id))
    {:noreply, assign(socket, selected_tile: tile)}
  end

  def handle_event("line_clicked", %{"line" => line_str}, socket) do
    case socket.assigns.selected_tile do
      nil ->
        {:noreply, socket}

      tile ->
        line = String.to_integer(line_str)
        available = Enum.reject(socket.assigns.available_tiles, &(&1.id == tile.id))
        placed = Map.update!(socket.assigns.placed_tiles, line, &(&1 ++ [tile]))

        {:noreply,
         assign(socket,
           available_tiles: available,
           placed_tiles: placed,
           selected_tile: nil
         )}
    end
  end

  def handle_event("tile_removed", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)

    {tile, placed} = remove_tile_from_lines(socket.assigns.placed_tiles, id)

    case tile do
      nil ->
        {:noreply, socket}

      tile ->
        {:noreply,
         assign(socket,
           available_tiles: socket.assigns.available_tiles ++ [tile],
           placed_tiles: placed
         )}
    end
  end

  def handle_event("submit_letter", _params, socket) do
    letter_text = build_letter_text(socket.assigns.placed_tiles)

    if String.trim(letter_text) == "" do
      {:noreply, socket}
    else
      # TODO: Wire up Mercury API judge in PR 5
      # For now, transition to judging and immediately return placeholder scores
      socket = assign(socket, phase: :judging)
      send(self(), {:judge_result, {:ok, placeholder_score()}})
      {:noreply, socket}
    end
  end

  def handle_event("next_round", _params, socket) do
    socket = assign(socket, round: socket.assigns.round + 1)
    {:noreply, start_round(socket)}
  end

  def handle_event("show_results", _params, socket) do
    {:noreply, assign(socket, phase: :game_over)}
  end

  def handle_event("play_again", _params, socket) do
    {:noreply,
     assign(socket,
       phase: :intro,
       round: 1,
       scores: [],
       total_score: 0,
       judging_error: nil
     )}
  end

  @impl true
  def handle_info({:judge_result, {:ok, result}}, socket) do
    score_entry = Map.put(result, :round, socket.assigns.round)
    round_score = result.relevance + result.creativity

    {:noreply,
     assign(socket,
       phase: :round_result,
       scores: [score_entry | socket.assigns.scores],
       total_score: socket.assigns.total_score + round_score,
       judging_error: nil
     )}
  end

  def handle_info({:judge_result, {:error, reason}}, socket) do
    {:noreply, assign(socket, phase: :playing, judging_error: inspect(reason))}
  end

  # -- Helpers --

  defp start_round(socket) do
    assign(socket,
      phase: :playing,
      prompt: WordPool.random_prompt(),
      available_tiles: WordPool.random_tiles(@tiles_per_round),
      placed_tiles: init_placed_tiles(),
      selected_tile: nil,
      judging_error: nil
    )
  end

  defp init_placed_tiles do
    Map.new(0..(@lines_on_stationery - 1), fn i -> {i, []} end)
  end

  defp remove_tile_from_lines(placed, id) do
    Enum.reduce(placed, {nil, placed}, fn {line, tiles}, {found, acc} ->
      case Enum.split_with(tiles, &(&1.id == id)) do
        {[tile], rest} -> {tile, Map.put(acc, line, rest)}
        _ -> {found, acc}
      end
    end)
  end

  defp build_letter_text(placed_tiles) do
    0..6
    |> Enum.map(fn line ->
      placed_tiles
      |> Map.get(line, [])
      |> Enum.map_join(" ", & &1.word)
    end)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  defp all_lines_empty?(placed_tiles) do
    Enum.all?(placed_tiles, fn {_line, tiles} -> tiles == [] end)
  end

  defp placeholder_score do
    %{relevance: Enum.random(3..8), creativity: Enum.random(3..8), commentary: "This is a placeholder score. The Mercury judge will be wired up soon!"}
  end

  defp rank_title(score, max) do
    pct = score / max * 100

    cond do
      pct >= 90 -> "Honorary Isabelle"
      pct >= 75 -> "Master Correspondent"
      pct >= 60 -> "Talented Penpal"
      pct >= 40 -> "Aspiring Author"
      pct >= 20 -> "Lazy Letter Writer"
      true -> "Nook's Least Favorite Customer"
    end
  end
end
