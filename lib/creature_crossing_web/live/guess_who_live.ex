defmodule CreatureCrossingWeb.GuessWhoLive do
  @moduledoc """
  Guess Who game with COM opponent using Animal Crossing NH villagers.

  Flow:
  1. Fetch villagers, randomly select 24 for the board
  2. Show 3 random choices for player to pick their secret villager
  3. COM picks its own secret, random first turn
  4. Players alternate: ask trait questions or make guesses
  5. COM answers player questions; player answers COM questions (lie detection)
  6. First to correctly guess opponent's secret wins
  """
  use CreatureCrossingWeb, :live_view

  alias CreatureCrossing.Nookipedia

  @board_size 24
  @com_delay_ms 1200

  @question_templates %{
    "species" => "Is your villager a %s?",
    "personality" => "Does your villager have a %s personality?",
    "gender" => "Is your villager %s?",
    "sign" => "Is your villager a %s?",
    "hobby" => "Does your villager enjoy %s?",
    "fav_colors" => "Is %s one of your villager's favorite colors?",
    "fav_styles" => "Is %s one of your villager's favorite styles?"
  }

  @category_labels [
    {"species", "Species"},
    {"personality", "Personality"},
    {"gender", "Gender"},
    {"sign", "Zodiac Sign"},
    {"hobby", "Hobby"},
    {"fav_colors", "Favorite Color"},
    {"fav_styles", "Favorite Style"}
  ]

  @all_categories ~w(species personality gender sign hobby fav_colors fav_styles)

  @impl true
  def mount(_params, _session, socket) do
    {:ok, all_villagers} = Nookipedia.list_villagers()

    villagers = Enum.filter(all_villagers, fn v -> v["role"] == "villager" end)

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
      com_secret: nil,
      eliminated: MapSet.new(),
      com_eliminated: MapSet.new(),
      phase: :picking,
      turn: nil,
      question_category: nil,
      question_value: nil,
      answer_modal: nil,
      com_question_modal: nil,
      liar_modal: false,
      liar_caught: false,
      history: [],
      com_history: [],
      guess_mode: false
    )
  end

  defp build_trait_options(board) do
    %{
      "species" => board |> Enum.map(& &1["species"]) |> Enum.uniq() |> Enum.sort(),
      "personality" => board |> Enum.map(& &1["personality"]) |> Enum.uniq() |> Enum.sort(),
      "gender" => board |> Enum.map(& &1["gender"]) |> Enum.uniq() |> Enum.sort(),
      "sign" => board |> Enum.map(& &1["sign"]) |> Enum.uniq() |> Enum.sort(),
      "hobby" => board |> Enum.map(& &1["hobby"]) |> Enum.uniq() |> Enum.sort(),
      "fav_colors" => board |> Enum.flat_map(& &1["fav_colors"]) |> Enum.uniq() |> Enum.sort(),
      "fav_styles" => board |> Enum.flat_map(& &1["fav_styles"]) |> Enum.uniq() |> Enum.sort()
    }
  end

  defp villager_matches_trait?(villager, category, value) do
    case category do
      cat when cat in ["fav_colors", "fav_styles"] ->
        value in (villager[cat] || [])

      _ ->
        villager[category] == value
    end
  end

  defp format_question(category, value) do
    template = @question_templates[category]
    String.replace(template, "%s", value)
  end

  defp com_remaining(socket) do
    socket.assigns.board
    |> Enum.reject(fn v ->
      MapSet.member?(socket.assigns.com_eliminated, v["name"]) ||
        v["name"] == socket.assigns.com_secret
    end)
  end

  defp schedule_com_turn(socket) do
    Process.send_after(self(), :com_turn, @com_delay_ms)
    assign(socket, turn: :com)
  end

  defp start_player_turn(socket) do
    assign(socket, turn: :player)
  end

  # COM picks a random question from categories that still have useful info
  defp com_pick_question(socket) do
    remaining = com_remaining(socket)
    trait_options = build_trait_options(remaining)
    already_asked = Enum.map(socket.assigns.com_history, fn e -> {e.category, e.value} end)

    # Try each category randomly until we find an un-asked combo
    categories = Enum.shuffle(@all_categories)

    Enum.find_value(categories, fn cat ->
      values = trait_options[cat] || []
      available = Enum.reject(values, fn v -> {cat, v} in already_asked end)

      case available do
        [] -> nil
        vals -> {cat, Enum.random(vals)}
      end
    end)
  end

  defp com_should_guess?(socket) do
    remaining_count = length(com_remaining(socket))
    remaining_count <= 3
  end

  defp com_make_guess(socket) do
    remaining = com_remaining(socket)
    guess = Enum.random(remaining)
    guess["name"]
  end

  # --- Events ---

  @impl true
  def handle_event("pick_secret", %{"name" => name}, socket) do
    com_secret =
      socket.assigns.board
      |> Enum.filter(fn v -> v["name"] != name end)
      |> Enum.random()
      |> Map.get("name")

    socket =
      assign(socket,
        secret: name,
        com_secret: com_secret,
        phase: :playing
      )
      |> start_player_turn()

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_category", %{"category" => category}, socket) do
    if socket.assigns.turn == :player do
      {:noreply, assign(socket, question_category: category, question_value: nil, guess_mode: false)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("select_value", %{"value" => value}, socket) do
    value = if value == "", do: nil, else: value
    {:noreply, assign(socket, question_value: value)}
  end

  @impl true
  def handle_event("ask_question", _params, socket) do
    if socket.assigns.turn != :player, do: {:noreply, socket}

    %{question_category: cat, question_value: val, com_secret: com_name, board: board} =
      socket.assigns

    com_villager = Enum.find(board, fn v -> v["name"] == com_name end)
    answer = villager_matches_trait?(com_villager, cat, val)
    question_text = format_question(cat, val)

    # Auto-eliminate from player's board
    eliminated = socket.assigns.eliminated

    new_eliminated =
      Enum.reduce(board, eliminated, fn villager, acc ->
        name = villager["name"]

        if name == socket.assigns.secret || MapSet.member?(acc, name) do
          acc
        else
          matches = villager_matches_trait?(villager, cat, val)

          if (answer && !matches) || (!answer && matches) do
            MapSet.put(acc, name)
          else
            acc
          end
        end
      end)

    entry = %{question: question_text, answer: answer, who: :player, category: cat, value: val}

    {:noreply,
     assign(socket,
       answer_modal: entry,
       eliminated: new_eliminated,
       history: [entry | socket.assigns.history],
       question_category: nil,
       question_value: nil
     )}
  end

  @impl true
  def handle_event("dismiss_modal", _params, socket) do
    # After player dismisses their answer modal, it's COM's turn
    socket = assign(socket, answer_modal: nil)
    {:noreply, schedule_com_turn(socket)}
  end

  @impl true
  def handle_event("toggle_guess_mode", _params, socket) do
    if socket.assigns.turn == :player do
      {:noreply, assign(socket, guess_mode: !socket.assigns.guess_mode, question_category: nil, question_value: nil)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("make_guess", %{"name" => name}, socket) do
    if socket.assigns.turn != :player, do: {:noreply, socket}

    correct = name == socket.assigns.com_secret

    if correct do
      entry = %{question: "You guessed #{name}", answer: true, who: :player}

      {:noreply,
       assign(socket,
         phase: :won,
         history: [entry | socket.assigns.history],
         guess_mode: false,
         answer_modal: nil
       )}
    else
      entry = %{question: "You guessed #{name}", answer: false, who: :player}
      eliminated = MapSet.put(socket.assigns.eliminated, name)

      {:noreply,
       assign(socket,
         history: [entry | socket.assigns.history],
         eliminated: eliminated,
         guess_mode: false,
         answer_modal: %{question: "Is it #{name}?", answer: false, guess: true}
       )}
    end
  end

  # Player answers COM's question
  @impl true
  def handle_event("answer_com", %{"answer" => given_answer}, socket) do
    %{com_question_modal: q, secret: secret_name, board: board} = socket.assigns
    secret_villager = Enum.find(board, fn v -> v["name"] == secret_name end)
    correct_answer = villager_matches_trait?(secret_villager, q.category, q.value)
    given_bool = given_answer == "yes"

    if given_bool != correct_answer do
      # Caught lying!
      {:noreply, assign(socket, liar_modal: true, liar_caught: true)}
    else
      # Honest answer — COM processes it
      {:noreply, process_com_answer(socket, correct_answer)}
    end
  end

  # Auto-honest answer after being caught lying
  @impl true
  def handle_event("answer_com_honest", _params, socket) do
    %{com_question_modal: q, secret: secret_name, board: board} = socket.assigns
    secret_villager = Enum.find(board, fn v -> v["name"] == secret_name end)
    correct_answer = villager_matches_trait?(secret_villager, q.category, q.value)
    {:noreply, process_com_answer(socket, correct_answer)}
  end

  @impl true
  def handle_event("dismiss_liar", _params, socket) do
    # After liar modal, send the correct answer anyway
    %{com_question_modal: q, secret: secret_name, board: board} = socket.assigns
    secret_villager = Enum.find(board, fn v -> v["name"] == secret_name end)
    correct_answer = villager_matches_trait?(secret_villager, q.category, q.value)

    {:noreply, socket |> assign(liar_modal: false) |> process_com_answer(correct_answer)}
  end

  @impl true
  def handle_event("dismiss_com_result", _params, socket) do
    # After seeing COM's question result, it's player's turn
    {:noreply, socket |> assign(com_question_modal: nil) |> start_player_turn()}
  end

  @impl true
  def handle_event("new_game", _params, socket) do
    {:noreply, new_game(socket)}
  end

  # --- COM turn logic ---

  defp process_com_answer(socket, answer) do
    q = socket.assigns.com_question_modal

    # COM eliminates from its internal board
    com_eliminated = socket.assigns.com_eliminated

    new_com_eliminated =
      Enum.reduce(socket.assigns.board, com_eliminated, fn villager, acc ->
        name = villager["name"]

        if name == socket.assigns.com_secret || MapSet.member?(acc, name) do
          acc
        else
          matches = villager_matches_trait?(villager, q.category, q.value)

          if (answer && !matches) || (!answer && matches) do
            MapSet.put(acc, name)
          else
            acc
          end
        end
      end)

    entry = %{question: q.question, answer: answer, who: :com, category: q.category, value: q.value}

    socket
    |> assign(
      com_eliminated: new_com_eliminated,
      com_history: [entry | socket.assigns.com_history],
      # Show result to player before continuing
      com_question_modal: Map.merge(q, %{answered: true, answer: answer})
    )
  end

  # Test helper to set state directly
  @impl true
  def handle_info({:set_test_state, assigns_map}, socket) do
    {:noreply, Enum.reduce(assigns_map, socket, fn {k, v}, s -> assign(s, k, v) end)}
  end

  @impl true
  def handle_info(:com_turn, socket) do
    if socket.assigns.phase != :playing do
      {:noreply, socket}
    else
      if com_should_guess?(socket) do
        guess_name = com_make_guess(socket)
        correct = guess_name == socket.assigns.secret

        if correct do
          entry = %{question: "COM guessed #{guess_name}", answer: true, who: :com}

          {:noreply,
           assign(socket,
             phase: :lost,
             com_history: [entry | socket.assigns.com_history]
           )}
        else
          entry = %{question: "COM guessed #{guess_name}", answer: false, who: :com}
          com_eliminated = MapSet.put(socket.assigns.com_eliminated, guess_name)

          {:noreply,
           assign(socket,
             com_history: [entry | socket.assigns.com_history],
             com_eliminated: com_eliminated,
             com_question_modal: %{question: "COM guessed: #{guess_name}", answer: false, guess: true, answered: true}
           )}
        end
      else
        case com_pick_question(socket) do
          nil ->
            # No more questions to ask, COM guesses
            guess_name = com_make_guess(socket)
            correct = guess_name == socket.assigns.secret

            if correct do
              entry = %{question: "COM guessed #{guess_name}", answer: true, who: :com}
              {:noreply, assign(socket, phase: :lost, com_history: [entry | socket.assigns.com_history])}
            else
              entry = %{question: "COM guessed #{guess_name}", answer: false, who: :com}
              com_eliminated = MapSet.put(socket.assigns.com_eliminated, guess_name)
              {:noreply, assign(socket,
                com_history: [entry | socket.assigns.com_history],
                com_eliminated: com_eliminated,
                com_question_modal: %{question: "COM guessed: #{guess_name}", answer: false, guess: true, answered: true}
              )}
            end

          {cat, val} ->
            question_text = format_question(cat, val)

            {:noreply,
             assign(socket,
               com_question_modal: %{
                 question: question_text,
                 category: cat,
                 value: val,
                 answered: false
               }
             )}
        end
      end
    end
  end

  # --- Render ---

  @impl true
  def render(assigns) do
    case assigns.phase do
      :picking -> render_picking(assigns)
      :playing -> render_playing(assigns)
      :won -> render_end(assigns, true)
      :lost -> render_end(assigns, false)
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
    trait_options = build_trait_options(assigns.board)
    secret_villager = Enum.find(assigns.board, fn v -> v["name"] == assigns.secret end)

    dropdown_values =
      if assigns.question_category,
        do: trait_options[assigns.question_category] || [],
        else: []

    can_ask = assigns.turn == :player && assigns.question_category != nil && assigns.question_value != nil
    is_player_turn = assigns.turn == :player

    assigns =
      assigns
      |> assign(:remaining, remaining)
      |> assign(:secret_villager, secret_villager)
      |> assign(:dropdown_values, dropdown_values)
      |> assign(:can_ask, can_ask)
      |> assign(:is_player_turn, is_player_turn)
      |> assign(:category_labels, @category_labels)

    ~H"""
    <div style="display: flex; gap: 1rem; padding: 0.25rem 1rem 1rem 1rem;">
      <%!-- Left panel: questions & history --%>
      <div style="width: 16rem; flex-shrink: 0;">
        <.question_panel
          category_labels={@category_labels}
          question_category={@question_category}
          question_value={@question_value}
          dropdown_values={@dropdown_values}
          can_ask={@can_ask}
          guess_mode={@guess_mode}
          history={@history}
          com_history={@com_history}
          is_player_turn={@is_player_turn}
        />
      </div>

      <%!-- Main board area --%>
      <div style="flex: 1;">
        <%!-- Header row --%>
        <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.5rem;">
          <button phx-click="new_game" class="btn btn-sm btn-ghost">
            <span class="hero-arrow-path" style="width: 1rem; height: 1rem;"></span>
            New Game
          </button>
          <h1 style="font-size: 2rem;" class="font-extrabold tracking-tight">Guess Who</h1>
          <div style="font-size: 0.875rem; text-align: right;">
            <p class="font-bold text-primary">{@remaining} remaining</p>
            <p style={"font-size: 0.75rem; font-weight: 600; color: #{if @is_player_turn, do: "var(--color-success)", else: "var(--color-warning)"};"}>
              {if @is_player_turn, do: "Your turn", else: "COM's turn..."}
            </p>
          </div>
        </div>

        <%!-- 6x4 board grid --%>
        <div style="display: grid; grid-template-columns: repeat(6, 1fr); gap: 0.75rem;">
          <div
            :for={villager <- @board}
            phx-click={if @guess_mode && @is_player_turn && !MapSet.member?(@eliminated, villager["name"]) && villager["name"] != @secret, do: "make_guess", else: nil}
            phx-value-name={villager["name"]}
            style={"border: 2px solid #{cond do
              villager["name"] == @secret -> "var(--color-primary)"
              @guess_mode && @is_player_turn && !MapSet.member?(@eliminated, villager["name"]) -> "var(--color-warning)"
              true -> "var(--color-neutral)"
            end}; border-radius: 0.75rem; padding: 0.5rem; background: var(--color-base-200); text-align: center; transition: opacity 0.2s;#{if MapSet.member?(@eliminated, villager["name"]), do: " opacity: 0.2;", else: ""}#{if @guess_mode && @is_player_turn && !MapSet.member?(@eliminated, villager["name"]) && villager["name"] != @secret, do: " cursor: pointer;", else: ""}"}
          >
            <img
              src={villager["image_url"]}
              alt=""
              style="width: 3.5rem; height: 3.5rem; object-fit: contain; margin: 0 auto 0.25rem auto; display: block;"
              loading="lazy"
              onerror="this.style.display='none'"
            />
            <p style="font-weight: 600; font-size: 0.75rem; line-height: 1.2; word-break: break-word; overflow-wrap: break-word;">
              {villager["name"]}
            </p>
          </div>
        </div>
      </div>

      <%!-- Right panel: your villager --%>
      <div style="width: 14rem; flex-shrink: 0;">
        <.villager_panel secret_villager={@secret_villager} />
      </div>
    </div>

    <%!-- Player's answer modal (after asking a question) --%>
    <.answer_modal :if={@answer_modal} answer_modal={@answer_modal} />

    <%!-- COM question modal (player must answer) --%>
    <.com_question_modal
      :if={@com_question_modal && !@liar_modal}
      com_question_modal={@com_question_modal}
      liar_caught={@liar_caught}
      secret_villager={@secret_villager}
    />

    <%!-- Liar modal --%>
    <.liar_modal :if={@liar_modal} />
    """
  end

  defp render_end(assigns, won) do
    assigns = assign(assigns, :won, won)

    ~H"""
    <div class="max-w-4xl mx-auto px-4" style="padding-top: 2rem; text-align: center;">
      <h1 style={"font-size: 3rem; margin-bottom: 0.5rem; color: #{if @won, do: "var(--color-success)", else: "var(--color-error)"};"} class="font-extrabold tracking-tight">
        {if @won, do: "You Win!", else: "You Lose!"}
      </h1>
      <p style="font-size: 1.25rem; margin-bottom: 0.5rem;" class="text-base-content/70">
        {if @won, do: "You correctly guessed", else: "COM correctly guessed your villager"}
      </p>
      <p :if={@won} style="margin-bottom: 0.5rem;">
        COM's secret was <span class="text-primary font-bold">{@com_secret}</span>
      </p>
      <p style="margin-bottom: 1.5rem;" class="text-base-content/70">
        Game lasted {length(@history) + length(@com_history)} turns
      </p>
      <button phx-click="new_game" class="btn btn-primary btn-lg">
        Play Again
      </button>
    </div>
    """
  end

  # --- Components ---

  defp question_panel(assigns) do
    ~H"""
    <div style="border: 2px solid var(--color-neutral); border-radius: 0.75rem; background: var(--color-base-200); overflow: hidden;">
      <%!-- Question controls --%>
      <div style="padding: 0.5rem; border-bottom: 2px solid var(--color-neutral);">
        <p style="font-weight: 700; font-size: 0.8rem; margin-bottom: 0.375rem;">Ask a Question</p>

        <%!-- Category buttons --%>
        <div style="display: flex; flex-wrap: wrap; gap: 0.25rem; margin-bottom: 0.375rem;">
          <button
            :for={{cat_key, cat_label} <- @category_labels}
            phx-click="select_category"
            phx-value-category={cat_key}
            disabled={!@is_player_turn}
            class={"btn btn-xs #{if @question_category == cat_key, do: "btn-primary", else: "btn-ghost"}"}
          >
            {cat_label}
          </button>
        </div>

        <%!-- Value dropdown --%>
        <form :if={@question_category} phx-change="select_value" style="margin-bottom: 0.375rem;">
          <select
            style="width: 100%; padding: 0.25rem 0.5rem; border-radius: 0.375rem; border: 1px solid var(--color-neutral); background: var(--color-base-100); font-size: 0.8rem;"
            name="value"
          >
            <option value="">Select...</option>
            <option :for={val <- @dropdown_values} value={val} selected={@question_value == val}>
              {val}
            </option>
          </select>
        </form>

        <%!-- Ask button --%>
        <button
          phx-click="ask_question"
          disabled={!@can_ask}
          class="btn btn-primary btn-sm btn-block"
        >
          Ask!
        </button>

        <%!-- Guess mode toggle --%>
        <div style="margin-top: 0.375rem; border-top: 1px solid color-mix(in oklch, var(--color-neutral) 40%, transparent); padding-top: 0.375rem;">
          <button
            phx-click="toggle_guess_mode"
            disabled={!@is_player_turn}
            class={"btn btn-sm btn-block #{if @guess_mode, do: "btn-warning", else: "btn-ghost"}"}
          >
            {if @guess_mode, do: "Cancel Guess", else: "Make a Guess"}
          </button>
          <p :if={@guess_mode} style="font-size: 0.7rem; opacity: 0.7; margin-top: 0.25rem; text-align: center;">
            Click a villager on the board to guess
          </p>
        </div>
      </div>

      <%!-- Question history --%>
      <div style="padding: 0.5rem; max-height: 14rem; overflow-y: auto;">
        <p style="font-weight: 700; font-size: 0.8rem; margin-bottom: 0.25rem;">History</p>
        <div :if={@history == [] && @com_history == []} style="font-size: 0.75rem; opacity: 0.5;">
          No questions yet
        </div>
        <%!-- Interleave player and COM history by showing all, newest first --%>
        <div
          :for={entry <- interleave_history(@history, @com_history)}
          style="font-size: 0.7rem; padding: 0.25rem 0; border-bottom: 1px solid color-mix(in oklch, var(--color-neutral) 20%, transparent);"
        >
          <p>
            <span :if={entry.who == :com} style="font-weight: 700; opacity: 0.6;">COM: </span>
            {entry.question}
          </p>
          <p style={"font-weight: 700; color: #{if entry.answer, do: "var(--color-success)", else: "var(--color-error)"};"}>
            {if entry.answer, do: "Yes", else: "No"}
          </p>
        </div>
      </div>
    </div>
    """
  end

  defp villager_panel(assigns) do
    ~H"""
    <div style="border: 2px solid var(--color-neutral); border-radius: 0.75rem; background: var(--color-base-200); overflow: hidden;">
      <div style="padding: 0.75rem; text-align: center; background: color-mix(in oklch, var(--color-primary) 10%, transparent);">
        <p style="font-weight: 700; font-size: 0.8rem; margin-bottom: 0.5rem;">Your Villager</p>
        <img
          src={@secret_villager["poster_url"] || @secret_villager["image_url"]}
          alt=""
          style="width: 6rem; height: auto; object-fit: contain; margin: 0 auto 0.25rem auto; display: block; border-radius: 0.375rem;"
          loading="lazy"
          onerror="this.src=this.dataset.fallback"
          data-fallback={@secret_villager["image_url"]}
        />
        <p class="text-primary" style="font-weight: 700; font-size: 0.9rem;">{@secret_villager["name"]}</p>
        <div style="font-size: 0.7rem; opacity: 0.7; margin-top: 0.25rem; text-align: left;">
          <p><strong>Species:</strong> {@secret_villager["species"]}</p>
          <p><strong>Personality:</strong> {@secret_villager["personality"]}</p>
          <p><strong>Gender:</strong> {@secret_villager["gender"]}</p>
          <p><strong>Sign:</strong> {@secret_villager["sign"]}</p>
          <p><strong>Hobby:</strong> {@secret_villager["hobby"]}</p>
          <p><strong>Colors:</strong> {Enum.join(@secret_villager["fav_colors"], ", ")}</p>
          <p><strong>Styles:</strong> {Enum.join(@secret_villager["fav_styles"], ", ")}</p>
        </div>
      </div>
    </div>
    """
  end

  defp answer_modal(assigns) do
    ~H"""
    <div style="position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 50;">
      <div style="background: var(--color-base-100); border: 2px solid var(--color-neutral); border-radius: 1rem; padding: 2rem; text-align: center; max-width: 24rem; width: 90%;">
        <p style="font-size: 1.1rem; margin-bottom: 1rem;">{@answer_modal.question}</p>
        <p style={"font-size: 2rem; font-weight: 800; margin-bottom: 1.5rem; color: #{if @answer_modal.answer, do: "var(--color-success)", else: "var(--color-error)"};"}>
          {if @answer_modal.answer, do: "Yes!", else: "No!"}
        </p>
        <p :if={Map.get(@answer_modal, :guess)} style="font-size: 0.875rem; opacity: 0.7; margin-bottom: 1rem;">
          Wrong guess — villager eliminated
        </p>
        <button phx-click="dismiss_modal" class="btn btn-primary btn-wide">
          Okay
        </button>
      </div>
    </div>
    """
  end

  defp com_question_modal(assigns) do
    answered = Map.get(assigns.com_question_modal, :answered, false)
    is_guess = Map.get(assigns.com_question_modal, :guess, false)
    assigns = assign(assigns, :answered, answered)
    assigns = assign(assigns, :is_guess, is_guess)

    ~H"""
    <div style="position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 50;">
      <div style="background: var(--color-base-100); border: 2px solid var(--color-neutral); border-radius: 1rem; padding: 2rem; text-align: center; max-width: 28rem; width: 90%;">
        <p style="font-weight: 700; font-size: 0.8rem; opacity: 0.6; margin-bottom: 0.5rem;">COM asks:</p>
        <p style="font-size: 1.1rem; margin-bottom: 1rem;">{@com_question_modal.question}</p>

        <%!-- Before answering: show Yes/No buttons (or auto-answer if caught lying before) --%>
        <div :if={!@answered && !@is_guess && !@liar_caught} style="display: flex; gap: 1rem; justify-content: center; margin-bottom: 1rem; flex-wrap: wrap;">
          <button phx-click="answer_com" phx-value-answer="yes" class="btn btn-success" style="min-width: 6rem;">
            Yes
          </button>
          <button phx-click="answer_com" phx-value-answer="no" class="btn btn-error" style="min-width: 6rem;">
            No
          </button>
        </div>
        <div :if={!@answered && !@is_guess && @liar_caught} style="text-align: center; margin-bottom: 1rem;">
          <p style="font-size: 0.8rem; opacity: 0.7; margin-bottom: 0.5rem;">no cheating &gt;:(</p>
          <button phx-click="answer_com_honest" class="btn btn-primary" style="min-width: 8rem;">
            Answer Honestly
          </button>
        </div>

        <%!-- After answering: show result --%>
        <div :if={@answered}>
          <p style={"font-size: 2rem; font-weight: 800; margin-bottom: 1rem; color: #{if @com_question_modal.answer, do: "var(--color-success)", else: "var(--color-error)"};"}>
            {if @com_question_modal.answer, do: "Yes!", else: "No!"}
          </p>
          <p :if={@is_guess} style="font-size: 0.875rem; opacity: 0.7; margin-bottom: 1rem;">
            COM guessed wrong!
          </p>
          <button phx-click="dismiss_com_result" class="btn btn-primary btn-wide">
            Continue
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp liar_modal(assigns) do
    ~H"""
    <div style="position: fixed; inset: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 60;">
      <div style="background: var(--color-base-100); border: 2px solid var(--color-error); border-radius: 1rem; padding: 2rem; text-align: center; max-width: 24rem; width: 90%;">
        <p style="font-size: 1.5rem; font-weight: 800; margin-bottom: 1rem;">
          booo you suck you liar
        </p>
        <button phx-click="dismiss_liar" class="btn btn-error btn-wide">
          I'm sorry :(
        </button>
      </div>
    </div>
    """
  end

  # Combine player and COM histories into a single newest-first list.
  # Each entry already has a :who field. Since turns alternate and both
  # lists are newest-first, we just zip them back together.
  defp interleave_history(player_history, com_history) do
    p = Enum.reverse(player_history)
    c = Enum.reverse(com_history)
    Enum.zip_with([p, c], fn [a, b] -> [a, b] end)
    |> List.flatten()
    |> Kernel.++(Enum.drop(p, length(c)) ++ Enum.drop(c, length(p)))
    |> Enum.reverse()
  end
end
