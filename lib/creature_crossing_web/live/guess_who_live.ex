defmodule CreatureCrossingWeb.GuessWhoLive do
  @moduledoc """
  Guess Who game using Animal Crossing NH villagers.

  Flow:
  1. Fetch villagers, randomly select 24 for the board
  2. Show 3 random choices from the 24 for player to pick their secret villager
  3. Player picks 1 — game begins with COM getting a random secret
  4. Player asks trait-based questions or makes guesses
  5. Answers auto-eliminate villagers from the board
  6. Correct guess wins the game
  """
  use CreatureCrossingWeb, :live_view

  alias CreatureCrossing.Nookipedia

  @board_size 24

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
      com_secret: nil,
      eliminated: MapSet.new(),
      phase: :picking,
      question_category: nil,
      question_value: nil,
      answer_modal: nil,
      history: [],
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

  # --- Events ---

  @impl true
  def handle_event("pick_secret", %{"name" => name}, socket) do
    com_secret =
      socket.assigns.board
      |> Enum.filter(fn v -> v["name"] != name end)
      |> Enum.random()
      |> Map.get("name")

    {:noreply, assign(socket, secret: name, com_secret: com_secret, phase: :playing)}
  end

  @impl true
  def handle_event("select_category", %{"category" => category}, socket) do
    {:noreply, assign(socket, question_category: category, question_value: nil, guess_mode: false)}
  end

  @impl true
  def handle_event("select_value", %{"value" => value}, socket) do
    value = if value == "", do: nil, else: value
    {:noreply, assign(socket, question_value: value)}
  end

  @impl true
  def handle_event("ask_question", _params, socket) do
    %{question_category: cat, question_value: val, com_secret: com_name, board: board} =
      socket.assigns

    com_villager = Enum.find(board, fn v -> v["name"] == com_name end)
    answer = villager_matches_trait?(com_villager, cat, val)
    question_text = format_question(cat, val)

    # Auto-eliminate based on answer
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

    entry = %{question: question_text, answer: answer}

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
    {:noreply, assign(socket, answer_modal: nil)}
  end

  @impl true
  def handle_event("toggle_guess_mode", _params, socket) do
    {:noreply, assign(socket, guess_mode: !socket.assigns.guess_mode, question_category: nil, question_value: nil)}
  end

  @impl true
  def handle_event("make_guess", %{"name" => name}, socket) do
    correct = name == socket.assigns.com_secret

    if correct do
      entry = %{question: "Guessed #{name}", answer: true}

      {:noreply,
       assign(socket,
         phase: :won,
         history: [entry | socket.assigns.history],
         guess_mode: false,
         answer_modal: nil
       )}
    else
      entry = %{question: "Guessed #{name}", answer: false}
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

  @impl true
  def handle_event("new_game", _params, socket) do
    {:noreply, new_game(socket)}
  end

  # --- Render ---

  @impl true
  def render(assigns) do
    case assigns.phase do
      :picking -> render_picking(assigns)
      :playing -> render_playing(assigns)
      :won -> render_won(assigns)
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

    can_ask = assigns.question_category != nil && assigns.question_value != nil

    assigns =
      assigns
      |> assign(:remaining, remaining)
      |> assign(:secret_villager, secret_villager)
      |> assign(:dropdown_values, dropdown_values)
      |> assign(:can_ask, can_ask)
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
          </div>
        </div>

        <%!-- 6x4 board grid --%>
        <div style="display: grid; grid-template-columns: repeat(6, 1fr); gap: 0.75rem;">
          <div
            :for={villager <- @board}
            phx-click={if @guess_mode && !MapSet.member?(@eliminated, villager["name"]) && villager["name"] != @secret, do: "make_guess", else: nil}
            phx-value-name={villager["name"]}
            style={"border: 2px solid #{cond do
              villager["name"] == @secret -> "var(--color-primary)"
              @guess_mode && !MapSet.member?(@eliminated, villager["name"]) -> "var(--color-warning)"
              true -> "var(--color-neutral)"
            end}; border-radius: 0.75rem; padding: 0.5rem; background: var(--color-base-200); text-align: center; transition: opacity 0.2s;#{if MapSet.member?(@eliminated, villager["name"]), do: " opacity: 0.2;", else: ""}#{if @guess_mode && !MapSet.member?(@eliminated, villager["name"]) && villager["name"] != @secret, do: " cursor: pointer;", else: ""}"}
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

      <%!-- Right panel: your villager --%>
      <div style="width: 14rem; flex-shrink: 0;">
        <.villager_panel secret_villager={@secret_villager} />
      </div>
    </div>

    <%!-- Answer modal --%>
    <.answer_modal :if={@answer_modal} answer_modal={@answer_modal} />
    """
  end

  defp render_won(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4" style="padding-top: 2rem; text-align: center;">
      <h1 style="font-size: 3rem; margin-bottom: 0.5rem;" class="font-extrabold tracking-tight">
        You Win!
      </h1>
      <p style="font-size: 1.25rem; margin-bottom: 0.5rem;" class="text-base-content/70">
        The secret villager was <span class="text-primary font-bold">{@com_secret}</span>
      </p>
      <p style="margin-bottom: 1.5rem;" class="text-base-content/70">
        Solved in {length(@history)} {if length(@history) == 1, do: "turn", else: "turns"}
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

        <%!-- Ask button — always visible, disabled until ready --%>
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
        <div :if={@history == []} style="font-size: 0.75rem; opacity: 0.5;">
          No questions yet
        </div>
        <div
          :for={entry <- @history}
          style="font-size: 0.7rem; padding: 0.25rem 0; border-bottom: 1px solid color-mix(in oklch, var(--color-neutral) 20%, transparent);"
        >
          <p>{entry.question}</p>
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
          src={@secret_villager["image_url"]}
          alt=""
          style="width: 3.5rem; height: 3.5rem; object-fit: contain; margin: 0 auto 0.25rem auto; display: block;"
          loading="lazy"
          onerror="this.style.display='none'"
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
end
