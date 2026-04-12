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
  alias CreatureCrossing.RansomNotes.Judge

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
        remaining_prompts: [],
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
            judging_error={@judging_error}
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
    <div id="ransom-notes-game" phx-hook=".RansomNotesDragDrop" class="flex flex-col items-center gap-4 w-full max-w-3xl">
      <%!-- Error alert --%>
      <div :if={@judging_error} class="alert alert-error max-w-lg">
        <span>Judging failed: {@judging_error}</span>
      </div>

      <%!-- Prompt --%>
      <div class="text-center">
        <p class="text-sm opacity-60 mb-1">Round {@round} of {@max_rounds}</p>
        <p class="text-xl font-bold">{@prompt}</p>
      </div>

      <%!-- NL Airmail Stationery --%>
      <div class="relative w-full rounded-sm shadow-lg" style="aspect-ratio: 4/3;">
        <%!-- Diagonal stripe border (airmail style) --%>
        <div class="absolute inset-0 rounded-sm overflow-hidden"
             style="background: repeating-linear-gradient(
               -45deg,
               #c41e3a 0px, #c41e3a 8px,
               #ffffff 8px, #ffffff 16px,
               #1a4b8c 16px, #1a4b8c 24px,
               #ffffff 24px, #ffffff 32px
             );">
        </div>
        <%!-- Inner white writing area --%>
        <div class="absolute rounded-sm bg-white"
             style="top: 14px; left: 14px; right: 14px; bottom: 14px;">
          <%!-- Stamp decoration (top-right) --%>
          <div class="absolute top-2 right-3 opacity-30" style="width: 36px; height: 36px;">
            <svg viewBox="0 0 36 36" fill="none" stroke="#888" stroke-width="1">
              <rect x="2" y="2" width="32" height="32" rx="1" stroke-dasharray="2 2" />
              <circle cx="18" cy="16" r="7" />
              <path d="M14 20 Q18 28 22 20" />
            </svg>
          </div>
          <%!-- Writing lines --%>
          <div class="absolute flex flex-col justify-evenly"
               style="top: 12%; left: 5%; right: 5%; bottom: 5%;">
            <div
              :for={line_idx <- 0..6}
              id={"line-#{line_idx}"}
              phx-click="line_clicked"
              phx-value-line={line_idx}
              data-line={line_idx}
              class="drop-zone flex flex-wrap gap-1 items-end cursor-pointer hover:bg-blue-50/50 transition-colors"
              style="flex: 1; border-bottom: 1px solid #c8c8c8; padding-bottom: 2px;"
            >
              <span
                :for={tile <- Map.get(@placed_tiles, line_idx, [])}
                phx-click="tile_removed"
                phx-value-id={tile.id}
                class="inline-block px-3 py-1 bg-amber-50 text-amber-950 border border-amber-300 rounded text-lg font-mono font-semibold cursor-pointer hover:bg-red-100 hover:border-red-400 transition-colors shadow-sm"
                style="transform: rotate({tile_rotation(tile.id)}deg);"
              >
                {tile.word}
              </span>
            </div>
          </div>
        </div>
      </div>

      <%!-- Available tiles --%>
      <div id="tile-pool" class="flex flex-wrap gap-1.5 justify-center w-full p-2 bg-base-200/50 rounded-lg">
        <span
          :for={tile <- @available_tiles}
          id={"tile-#{tile.id}"}
          phx-click="tile_selected"
          phx-value-id={tile.id}
          draggable="true"
          data-tile-id={tile.id}
          class={[
            "tile-draggable inline-block px-2 py-1 border rounded text-sm font-mono cursor-grab transition-all select-none shadow-sm",
            if(@selected_tile && @selected_tile.id == tile.id,
              do: "bg-primary text-primary-content border-primary scale-110 shadow-md",
              else: "bg-amber-50 text-amber-950 border-amber-300 hover:bg-amber-100 hover:border-amber-400 hover:shadow-md"
            )
          ]}
          style={"transform: rotate(#{tile_rotation(tile.id)}deg);"}
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

    <script :type={Phoenix.LiveView.ColocatedHook} name=".RansomNotesDragDrop">
      export default {
        mounted() {
          // Drag start on tiles
          this.el.addEventListener("dragstart", (e) => {
            const tile = e.target.closest(".tile-draggable");
            if (!tile) return;
            e.dataTransfer.setData("text/plain", tile.dataset.tileId);
            e.dataTransfer.effectAllowed = "move";
            tile.classList.add("opacity-50");
          });

          this.el.addEventListener("dragend", (e) => {
            const tile = e.target.closest(".tile-draggable");
            if (tile) tile.classList.remove("opacity-50");
          });

          // Drop zones
          this.el.addEventListener("dragover", (e) => {
            const zone = e.target.closest(".drop-zone");
            if (!zone) return;
            e.preventDefault();
            e.dataTransfer.dropEffect = "move";
            zone.classList.add("bg-primary/10");
          });

          this.el.addEventListener("dragleave", (e) => {
            const zone = e.target.closest(".drop-zone");
            if (zone) zone.classList.remove("bg-primary/10");
          });

          this.el.addEventListener("drop", (e) => {
            e.preventDefault();
            const zone = e.target.closest(".drop-zone");
            if (!zone) return;
            zone.classList.remove("bg-primary/10");
            const tileId = e.dataTransfer.getData("text/plain");
            const line = parseInt(zone.dataset.line);
            if (tileId && !isNaN(line)) {
              this.pushEvent("tile_dropped", {tile_id: parseInt(tileId), line: line});
            }
          });

          // Touch support: tap tile to select, tap line to place
          // (Already handled by phx-click events, no extra JS needed)
        }
      };
    </script>
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

      <%!-- Isabelle's interpretation --%>
      <div :if={@latest.line_interpretations != [] or @latest.overall_interpretation != ""}
           class="bg-base-100 border border-base-300 rounded-xl p-4 mb-4 text-left text-sm">
        <p class="font-bold mb-2 text-center">How Isabelle read your letter:</p>
        <div :if={@latest.line_interpretations != []} class="space-y-1 mb-3">
          <p :for={{interp, idx} <- Enum.with_index(@latest.line_interpretations, 1)}>
            <span class="font-semibold opacity-60">Line {idx}:</span> {interp}
          </p>
        </div>
        <div :if={@latest.overall_interpretation != ""} class="border-t border-base-300 pt-2">
          <p><span class="font-semibold">Overall:</span> {@latest.overall_interpretation}</p>
        </div>
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
    prompts = WordPool.all_prompts() |> Enum.shuffle()
    socket = assign(socket, remaining_prompts: prompts)
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

  def handle_event("tile_dropped", %{"tile_id" => tile_id, "line" => line}, socket) do
    tile = Enum.find(socket.assigns.available_tiles, &(&1.id == tile_id))

    case tile do
      nil ->
        {:noreply, socket}

      tile ->
        available = Enum.reject(socket.assigns.available_tiles, &(&1.id == tile_id))
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
      socket = assign(socket, phase: :judging)
      Judge.judge_async(socket.assigns.prompt, letter_text)
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
    [prompt | rest] = socket.assigns.remaining_prompts

    assign(socket,
      phase: :playing,
      prompt: prompt,
      remaining_prompts: rest,
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

  defp tile_rotation(id) do
    rem(id * 7, 7) - 3
  end

  defp all_lines_empty?(placed_tiles) do
    Enum.all?(placed_tiles, fn {_line, tiles} -> tiles == [] end)
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
