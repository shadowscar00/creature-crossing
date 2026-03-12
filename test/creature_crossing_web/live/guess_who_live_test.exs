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

  test "shows villager names and species in choices", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/guess-who")
    assert html =~ "·"
  end

  # --- Board / playing phase tests ---

  test "picking a secret villager transitions to playing phase", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/guess-who")
    [_, name] = Regex.run(~r/phx-click="pick_secret"\s+phx-value-name="([^"]+)"/, html)

    html = view |> element(~s(div[phx-value-name="#{name}"][phx-click="pick_secret"])) |> render_click()

    assert html =~ "remaining"
    assert html =~ name
    refute html =~ "Pick your secret villager!"
  end

  test "board has 24 villagers in playing phase", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    html = render(view)
    # Count villager cards by their phx-value-name attributes in the board grid
    matches = Regex.scan(~r/phx-value-name="[^"]+"/, html)
    assert length(matches) == 24
  end

  test "shows 24 remaining at start", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    html = render(view)
    assert html =~ "24 remaining"
  end

  test "new game resets to picking phase", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    html = view |> element("button", "New Game") |> render_click()
    assert html =~ "Pick your secret villager!"
  end

  test "secret villager has primary border highlight", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    secret_name = pick_first_secret(view)

    html = render(view)
    assert html =~ "var(--color-primary)"
    assert html =~ secret_name
  end

  # --- Side panels tests ---

  test "right panel shows secret villager traits", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    html = render(view)
    assert html =~ "Your Villager"
    assert html =~ "Species:"
    assert html =~ "Personality:"
    assert html =~ "Gender:"
    assert html =~ "Sign:"
    assert html =~ "Hobby:"
    assert html =~ "Colors:"
    assert html =~ "Styles:"
  end

  test "left panel shows question controls and empty history", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    html = render(view)
    assert html =~ "Ask a Question"
    assert html =~ "No questions yet"
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
    assert html =~ "Zodiac Sign"
    assert html =~ "Hobby"
    assert html =~ "Favorite Color"
    assert html =~ "Favorite Style"
  end

  test "selecting a category shows value dropdown", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    html = view |> element(~s(button[phx-value-category="gender"])) |> render_click()
    assert html =~ "Select..."
    assert html =~ "Male"
    assert html =~ "Female"
  end

  test "ask button is disabled until category and value selected", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    html = render(view)
    # Ask button should be present but disabled
    assert html =~ "Ask!"
    assert html =~ "disabled"
  end

  test "asking a question shows answer modal", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    view |> element(~s(button[phx-value-category="gender"])) |> render_click()
    view |> element("form") |> render_change(%{"value" => "Male"})

    html = view |> element(~s(button[phx-click="ask_question"])) |> render_click()

    assert html =~ "Male"
    assert html =~ ~r/(Yes!|No!)/
    assert html =~ "Okay"
  end

  test "dismissing modal hides it", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    view |> element(~s(button[phx-value-category="gender"])) |> render_click()
    view |> element("form") |> render_change(%{"value" => "Male"})
    view |> element(~s(button[phx-click="ask_question"])) |> render_click()

    html = view |> element(~s(button[phx-click="dismiss_modal"])) |> render_click()
    refute html =~ "Okay"
  end

  test "question appears in history after asking", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    view |> element(~s(button[phx-value-category="gender"])) |> render_click()
    view |> element("form") |> render_change(%{"value" => "Male"})
    view |> element(~s(button[phx-click="ask_question"])) |> render_click()
    view |> element(~s(button[phx-click="dismiss_modal"])) |> render_click()

    html = render(view)
    assert html =~ "Male"
    refute html =~ "No questions yet"
  end

  test "asking a question auto-eliminates villagers", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    view |> element(~s(button[phx-value-category="gender"])) |> render_click()
    view |> element("form") |> render_change(%{"value" => "Male"})
    view |> element(~s(button[phx-click="ask_question"])) |> render_click()
    html = view |> element(~s(button[phx-click="dismiss_modal"])) |> render_click()

    # Some villagers should be eliminated (not 24 remaining)
    refute html =~ "24 remaining"
  end

  test "board villagers are not manually clickable for elimination", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    html = render(view)
    # No toggle_eliminate events should be on the board
    refute html =~ "toggle_eliminate"
  end

  # --- Guess mode tests ---

  test "toggling guess mode highlights board", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    html = view |> element("button", "Make a Guess") |> render_click()
    assert html =~ "Cancel Guess"
    assert html =~ "Click a villager on the board to guess"
    assert html =~ "var(--color-warning)"
  end

  test "wrong guess shows modal and does not eliminate", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    secret_name = pick_first_secret(view)

    state = :sys.get_state(view.pid)
    com_secret = state.socket.assigns.com_secret

    view |> element("button", "Make a Guess") |> render_click()

    # Find a villager that is neither player's nor COM's secret
    html = render(view)
    target =
      Regex.scan(~r/phx-click="make_guess"\s+phx-value-name="([^"]+)"/, html)
      |> Enum.map(fn [_, n] -> n end)
      |> Enum.find(fn n -> n != secret_name && n != com_secret end)

    html = view |> element(~s(div[phx-value-name="#{target}"][phx-click="make_guess"])) |> render_click()
    assert html =~ "No!"
    assert html =~ "Wrong guess"

    html = view |> element(~s(button[phx-click="dismiss_modal"])) |> render_click()
    assert html =~ "24 remaining"
  end

  test "correct guess wins the game", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    state = :sys.get_state(view.pid)
    com_secret = state.socket.assigns.com_secret

    view |> element("button", "Make a Guess") |> render_click()
    html = view |> element(~s(div[phx-value-name="#{com_secret}"][phx-click="make_guess"])) |> render_click()

    assert html =~ "You Win!"
    assert html =~ com_secret
    assert html =~ "Play Again"
  end

  test "play again from win screen starts new game", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    state = :sys.get_state(view.pid)
    com_secret = state.socket.assigns.com_secret

    view |> element("button", "Make a Guess") |> render_click()
    view |> element(~s(div[phx-value-name="#{com_secret}"][phx-click="make_guess"])) |> render_click()

    html = view |> element("button", "Play Again") |> render_click()
    assert html =~ "Pick your secret villager!"
  end

  # --- Helpers ---

  defp pick_first_secret(view) do
    html = render(view)
    [_, name] = Regex.run(~r/phx-click="pick_secret"\s+phx-value-name="([^"]+)"/, html)
    view |> element(~s(div[phx-value-name="#{name}"][phx-click="pick_secret"])) |> render_click()
    name
  end
end
