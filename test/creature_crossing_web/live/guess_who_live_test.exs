defmodule CreatureCrossingWeb.GuessWhoLiveTest do
  use CreatureCrossingWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders picking phase with 3 villager choices", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/guess-who")
    assert html =~ "Guess Who"
    assert html =~ "Pick your secret villager!"

    # Should have exactly 3 pick_secret click targets
    matches = Regex.scan(~r/phx-click="pick_secret"/, html)
    assert length(matches) == 3
  end

  test "sets page title", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/guess-who")
    assert html =~ "Guess Who"
  end

  test "shows villager names and species in choices", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/guess-who")
    # At least one choice should have species info (· separator)
    assert html =~ "·"
  end

  test "picking a secret villager transitions to playing phase", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/guess-who")

    # Extract the first choice name
    [_, name] = Regex.run(~r/phx-click="pick_secret"\s+phx-value-name="([^"]+)"/, html)

    html = view |> element(~s(div[phx-value-name="#{name}"][phx-click="pick_secret"])) |> render_click()

    # Should now show the game board
    assert html =~ "remaining"
    assert html =~ "Your secret:"
    assert html =~ name
    refute html =~ "Pick your secret villager!"
  end

  test "board has 24 villagers in playing phase", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    html = render(view)
    # Count toggle_eliminate click targets (24 board villagers)
    matches = Regex.scan(~r/phx-click="toggle_eliminate"/, html)
    assert length(matches) == 24
  end

  test "shows 24 remaining at start", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    html = render(view)
    assert html =~ "24 remaining"
  end

  test "clicking a villager eliminates them (reduces remaining count)", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    secret_name = pick_first_secret(view)

    html = render(view)
    target = find_non_secret_villager(html, secret_name)

    html = view |> element(~s(div[phx-value-name="#{target}"][phx-click="toggle_eliminate"])) |> render_click()
    assert html =~ "23 remaining"
  end

  test "clicking an eliminated villager un-eliminates them", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    secret_name = pick_first_secret(view)

    html = render(view)
    target = find_non_secret_villager(html, secret_name)

    # Eliminate
    view |> element(~s(div[phx-value-name="#{target}"][phx-click="toggle_eliminate"])) |> render_click()
    # Un-eliminate
    html = view |> element(~s(div[phx-value-name="#{target}"][phx-click="toggle_eliminate"])) |> render_click()
    assert html =~ "24 remaining"
  end

  test "cannot eliminate the secret villager", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    secret_name = pick_first_secret(view)

    html = view |> element(~s(div[phx-value-name="#{secret_name}"][phx-click="toggle_eliminate"])) |> render_click()
    assert html =~ "24 remaining"
  end

  test "new game resets to picking phase", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    pick_first_secret(view)

    html = view |> element("button", "New Game") |> render_click()
    assert html =~ "Pick your secret villager!"
    refute html =~ "remaining"
  end

  test "secret villager has primary border highlight", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/guess-who")
    secret_name = pick_first_secret(view)

    html = render(view)
    assert html =~ "var(--color-primary)"
    assert html =~ "Your secret:"
    assert html =~ secret_name
  end

  # Helper to pick the first available secret and return its name
  defp pick_first_secret(view) do
    html = render(view)
    [_, name] = Regex.run(~r/phx-click="pick_secret"\s+phx-value-name="([^"]+)"/, html)
    view |> element(~s(div[phx-value-name="#{name}"][phx-click="pick_secret"])) |> render_click()
    name
  end

  defp find_non_secret_villager(html, secret_name) do
    Regex.scan(~r/phx-click="toggle_eliminate"\s+phx-value-name="([^"]+)"/, html)
    |> Enum.map(fn [_, n] -> n end)
    |> Enum.find(fn n -> n != secret_name end)
  end
end
