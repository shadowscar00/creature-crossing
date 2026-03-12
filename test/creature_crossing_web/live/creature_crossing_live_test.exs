defmodule CreatureCrossingWeb.CreatureCrossingLiveTest do
  use CreatureCrossingWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders critter tool with tabs", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/creature-crossing")
    assert html =~ "Critter Tool"
    assert html =~ "Bugs"
    assert html =~ "Fish"
    assert html =~ "Diving"
  end

  test "sets page title", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/creature-crossing")
    assert html =~ "Critter Tool"
  end

  test "renders critter names from stub data", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/creature-crossing")
    # Bugs tab is active by default — should see stub bug names
    assert html =~ "Common butterfly"
  end

  test "hemisphere toggle switches label", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/creature-crossing")
    assert render(view) =~ "Northern"

    html = view |> element("button", "Northern") |> render_click()
    assert html =~ "Southern"
  end

  test "flip mode toggles selection label", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/creature-crossing")
    assert render(view) =~ "I&#39;m missing these"

    html = view |> element("button", "missing these") |> render_click()
    assert html =~ "I have these"
  end

  test "clicking a critter toggles selection", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/creature-crossing")

    html = view |> element(~s(li[phx-value-name="Common butterfly"])) |> render_click()
    assert html =~ "1 selected"

    html = view |> element(~s(li[phx-value-name="Common butterfly"])) |> render_click()
    assert html =~ "0 selected"
  end

  test "calculate button is disabled until 5 critters selected", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/creature-crossing")
    assert html =~ "disabled"
    assert html =~ "need 5 more"

    # Select 5 critters
    for name <- ["Common butterfly", "Monarch butterfly", "Honeybee", "Tarantula", "Emperor butterfly"] do
      view |> element(~s(li[phx-value-name="#{name}"])) |> render_click()
    end

    html = render(view)
    assert html =~ "5 selected"
    refute html =~ "need"
  end

  test "switching tabs shows different critter lists", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/creature-crossing")

    html = view |> element("button", "Fish") |> render_click()
    # Should see a fish from stub data
    assert html =~ "Sea bass"
  end

  test "selections persist across tab switches", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/creature-crossing")

    # Select a bug
    view |> element(~s(li[phx-value-name="Common butterfly"])) |> render_click()

    # Switch to fish and back
    view |> element("button", "Fish") |> render_click()
    html = view |> element("button", "Bugs") |> render_click()

    assert html =~ "1 selected"
  end
end
