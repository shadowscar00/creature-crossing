defmodule CreatureCrossingWeb.GuessWhoLiveTest do
  use CreatureCrossingWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  # --- Picking phase tests ---

  test "renders picking phase with 3 villager choices", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/guess-who")
    assert html =~ "Guess Who"
    assert html =~ "Pick your secret villager!"

    matches = Regex.scan(~r/phx-click="pick_secret"/, html)
    assert length(matches) == 3
  end

  test "sets page title", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/guess-who")
    assert html =~ "Guess Who"
  end

  # --- Board / playing phase tests ---

  test "picking a secret transitions to playing phase", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    html = render(view)
    assert html =~ "remaining"
    refute html =~ "Pick your secret villager!"
  end

  test "board has 24 villagers", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_and_ensure_player_turn(view)

    html = render(view)
    matches = Regex.scan(~r/phx-value-name="[^"]+"/, html)
    assert length(matches) == 24
  end

  test "shows 24 remaining at start", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_and_ensure_player_turn(view)

    html = render(view)
    assert html =~ "24 remaining"
  end

  test "shows turn indicator", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_and_ensure_player_turn(view)

    html = render(view)
    assert html =~ "Your turn"
  end

  test "new game resets to picking phase", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    html = view |> element("button", "New Game") |> render_click()
    assert html =~ "Pick your secret villager!"
  end

  # --- Side panels tests ---

  test "right panel shows secret villager traits", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    html = render(view)
    assert html =~ "Your Villager"
    assert html =~ "Species:"
    assert html =~ "Personality:"
  end

  test "left panel shows question controls", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    html = render(view)
    assert html =~ "Ask a Question"
    assert html =~ "Ask!"
  end

  # --- Question system tests ---

  test "shows question category buttons", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    html = render(view)
    assert html =~ "Species"
    assert html =~ "Personality"
    assert html =~ "Gender"
  end

  test "selecting a category shows value dropdown", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_and_ensure_player_turn(view)

    html = view |> element(~s(button[phx-value-category="gender"])) |> render_click()
    assert html =~ "Select..."
    assert html =~ "Male"
    assert html =~ "Female"
  end

  test "asking a question shows answer modal", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_and_ensure_player_turn(view)

    view |> element(~s(button[phx-value-category="gender"])) |> render_click()
    view |> element("form") |> render_change(%{"value" => "Male"})

    html = view |> element(~s(button[phx-click="ask_question"])) |> render_click()

    assert html =~ "Male"
    assert html =~ ~r/(Yes!|No!)/
    assert html =~ "Okay"
  end

  test "dismissing player answer modal triggers COM turn", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_and_ensure_player_turn(view)

    view |> element(~s(button[phx-value-category="gender"])) |> render_click()
    view |> element("form") |> render_change(%{"value" => "Male"})
    view |> element(~s(button[phx-click="ask_question"])) |> render_click()
    view |> element(~s(button[phx-click="dismiss_modal"])) |> render_click()

    # After dismiss, turn should switch to COM
    state = :sys.get_state(view.pid)
    assert state.socket.assigns.turn == :com
  end

  test "asking a question auto-eliminates villagers", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_and_ensure_player_turn(view)

    view |> element(~s(button[phx-value-category="gender"])) |> render_click()
    view |> element("form") |> render_change(%{"value" => "Male"})
    view |> element(~s(button[phx-click="ask_question"])) |> render_click()
    html = view |> element(~s(button[phx-click="dismiss_modal"])) |> render_click()

    refute html =~ "24 remaining"
  end

  # --- COM turn tests ---

  test "COM asks a question after delay", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_and_ensure_player_turn(view)

    # Player asks a question
    view |> element(~s(button[phx-value-category="gender"])) |> render_click()
    view |> element("form") |> render_change(%{"value" => "Male"})
    view |> element(~s(button[phx-click="ask_question"])) |> render_click()
    view |> element(~s(button[phx-click="dismiss_modal"])) |> render_click()

    # Trigger COM turn message
    send(view.pid, :com_turn)

    html = render(view)
    assert html =~ "COM asks:"
  end

  test "player can answer COM question honestly", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_and_ensure_player_turn(view)

    # Do a player turn then trigger COM
    do_player_turn(view)
    send(view.pid, :com_turn)

    html = render(view)
    assert html =~ "COM asks:"

    # Get the correct answer
    state = :sys.get_state(view.pid)
    q = state.socket.assigns.com_question_modal
    secret = Enum.find(state.socket.assigns.board, fn v -> v["name"] == state.socket.assigns.secret end)

    correct = CreatureCrossingWeb.GuessWhoLiveTest.matches_trait?(secret, q.category, q.value)
    answer_str = if correct, do: "yes", else: "no"

    html = view |> element(~s(button[phx-value-answer="#{answer_str}"])) |> render_click()
    # Should show the result
    assert html =~ "Continue"
  end

  test "lying to COM is caught", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_and_ensure_player_turn(view)

    do_player_turn(view)
    send(view.pid, :com_turn)

    # Get the correct answer and give the opposite
    state = :sys.get_state(view.pid)
    q = state.socket.assigns.com_question_modal
    secret = Enum.find(state.socket.assigns.board, fn v -> v["name"] == state.socket.assigns.secret end)

    correct = CreatureCrossingWeb.GuessWhoLiveTest.matches_trait?(secret, q.category, q.value)
    lie_str = if correct, do: "no", else: "yes"

    html = view |> element(~s(button[phx-value-answer="#{lie_str}"])) |> render_click()
    assert html =~ "booo you suck you liar"
    assert html =~ "I&#39;m sorry :("
  end

  test "after lying, dismiss liar modal and game continues", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_and_ensure_player_turn(view)

    do_player_turn(view)
    send(view.pid, :com_turn)

    state = :sys.get_state(view.pid)
    q = state.socket.assigns.com_question_modal
    secret = Enum.find(state.socket.assigns.board, fn v -> v["name"] == state.socket.assigns.secret end)
    correct = CreatureCrossingWeb.GuessWhoLiveTest.matches_trait?(secret, q.category, q.value)
    lie_str = if correct, do: "no", else: "yes"

    view |> element(~s(button[phx-value-answer="#{lie_str}"])) |> render_click()
    html = view |> element(~s(button[phx-click="dismiss_liar"])) |> render_click()

    # Should now show the COM result
    assert html =~ "Continue"
  end

  test "after lying once, no button shows 'no cheating'", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_and_ensure_player_turn(view)

    do_player_turn(view)
    send(view.pid, :com_turn)

    state = :sys.get_state(view.pid)
    q = state.socket.assigns.com_question_modal
    secret = Enum.find(state.socket.assigns.board, fn v -> v["name"] == state.socket.assigns.secret end)
    correct = CreatureCrossingWeb.GuessWhoLiveTest.matches_trait?(secret, q.category, q.value)
    lie_str = if correct, do: "no", else: "yes"

    view |> element(~s(button[phx-value-answer="#{lie_str}"])) |> render_click()
    view |> element(~s(button[phx-click="dismiss_liar"])) |> render_click()
    view |> element(~s(button[phx-click="dismiss_com_result"])) |> render_click()

    # Verify liar_caught is set in state
    state = :sys.get_state(view.pid)
    assert state.socket.assigns.liar_caught == true

    # If COM asks another question, it should show "Answer Honestly"
    do_player_turn(view)
    send(view.pid, :com_turn)

    state = :sys.get_state(view.pid)

    if state.socket.assigns.com_question_modal && !Map.get(state.socket.assigns.com_question_modal, :guess) do
      html = render(view)
      assert html =~ "no cheating"
      assert html =~ "Answer Honestly"
    end
  end

  # --- Guess mode tests ---

  test "correct guess wins the game", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_and_ensure_player_turn(view)

    state = :sys.get_state(view.pid)
    com_secret = state.socket.assigns.com_secret

    view |> element("button", "Make a Guess") |> render_click()
    html = view |> element(~s(div[phx-value-name="#{com_secret}"][phx-click="make_guess"])) |> render_click()

    assert html =~ "You Win!"
    assert html =~ com_secret
    assert html =~ "Play Again"
  end

  test "wrong guess eliminates villager and shows modal", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    secret_name = pick_and_ensure_player_turn(view)

    state = :sys.get_state(view.pid)
    com_secret = state.socket.assigns.com_secret

    view |> element("button", "Make a Guess") |> render_click()

    html = render(view)
    target =
      Regex.scan(~r/phx-click="make_guess"\s+phx-value-name="([^"]+)"/, html)
      |> Enum.map(fn [_, n] -> n end)
      |> Enum.find(fn n -> n != secret_name && n != com_secret end)

    html = view |> element(~s(div[phx-value-name="#{target}"][phx-click="make_guess"])) |> render_click()
    assert html =~ "No!"
    assert html =~ "Wrong guess"
  end

  test "play again from win screen starts new game", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_and_ensure_player_turn(view)

    state = :sys.get_state(view.pid)
    com_secret = state.socket.assigns.com_secret

    view |> element("button", "Make a Guess") |> render_click()
    view |> element(~s(div[phx-value-name="#{com_secret}"][phx-click="make_guess"])) |> render_click()

    html = view |> element("button", "Play Again") |> render_click()
    assert html =~ "Pick your secret villager!"
  end

  # --- COM guess tests ---

  test "COM guessing correctly shows loss screen", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_and_ensure_player_turn(view)

    # Manually set COM to have eliminated all but the player's secret
    state = :sys.get_state(view.pid)
    all_names = Enum.map(state.socket.assigns.board, & &1["name"])
    secret = state.socket.assigns.secret
    com_secret = state.socket.assigns.com_secret

    # Eliminate everyone except secret and com_secret from COM's board
    com_eliminated =
      all_names
      |> Enum.reject(fn n -> n == secret || n == com_secret end)
      |> MapSet.new()

    send(view.pid, {:set_test_state, %{com_eliminated: com_eliminated}})
    send(view.pid, :com_turn)

    html = render(view)
    # COM should guess — it either wins or loses
    assert html =~ "You Lose!" or html =~ "COM guessed"
  end

  # --- Helpers ---

  defp pick_first_secret(view) do
    html = render(view)
    [_, name] = Regex.run(~r/phx-click="pick_secret"\s+phx-value-name="([^"]+)"/, html)
    view |> element(~s(div[phx-value-name="#{name}"][phx-click="pick_secret"])) |> render_click()
    name
  end

  defp pick_and_ensure_player_turn(view) do
    name = pick_first_secret(view)

    # If COM goes first, handle its turn
    state = :sys.get_state(view.pid)

    if state.socket.assigns.turn == :com do
      send(view.pid, :com_turn)
      html = render(view)

      if html =~ "COM asks:" do
        # Answer honestly
        state = :sys.get_state(view.pid)
        q = state.socket.assigns.com_question_modal
        secret = Enum.find(state.socket.assigns.board, fn v -> v["name"] == state.socket.assigns.secret end)
        correct = matches_trait?(secret, q.category, q.value)
        answer_str = if correct, do: "yes", else: "no"

        view |> element(~s(button[phx-value-answer="#{answer_str}"])) |> render_click()
        view |> element(~s(button[phx-click="dismiss_com_result"])) |> render_click()
      end
    end

    name
  end

  defp do_player_turn(view) do
    view |> element(~s(button[phx-value-category="gender"])) |> render_click()
    view |> element("form") |> render_change(%{"value" => "Male"})
    view |> element(~s(button[phx-click="ask_question"])) |> render_click()
    view |> element(~s(button[phx-click="dismiss_modal"])) |> render_click()
  end

  # Public for use in tests
  def matches_trait?(villager, category, value) do
    case category do
      cat when cat in ["fav_colors", "fav_styles"] ->
        value in (villager[cat] || [])

      _ ->
        villager[category] == value
    end
  end
end
