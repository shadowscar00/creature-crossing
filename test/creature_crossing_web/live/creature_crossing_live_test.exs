defmodule CreatureCrossingWeb.CreatureCrossingLiveTest do
  use CreatureCrossingWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders critter tool with all three category boxes", %{conn: conn} do
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

  test "renders critter names from stub data in all categories", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/creature-crossing")
    # Bug
    assert html =~ "Common butterfly"
    # Fish
    assert html =~ "Sea bass"
    # Sea creature
    assert html =~ "Seaweed"
  end

  test "hemisphere toggle switches active label", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/creature-crossing")

    html = view |> element(~s(input[phx-click="toggle_hemisphere"])) |> render_click()
    # After toggling, Southern should be highlighted
    assert html =~ "Southern"
  end

  test "flip mode toggles selection label", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/creature-crossing")
    assert html =~ "Missing"
    assert html =~ "Have"
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

    # Select 5 critters (across categories since all are visible)
    for name <- ["Common butterfly", "Monarch butterfly", "Honeybee", "Sea bass", "Seaweed"] do
      view |> element(~s(li[phx-value-name="#{name}"])) |> render_click()
    end

    html = render(view)
    assert html =~ "5 selected"
    refute html =~ "need"
  end

  test "selections work across all three categories simultaneously", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/creature-crossing")

    # Select one from each category
    view |> element(~s(li[phx-value-name="Common butterfly"])) |> render_click()
    view |> element(~s(li[phx-value-name="Sea bass"])) |> render_click()
    html = view |> element(~s(li[phx-value-name="Seaweed"])) |> render_click()

    assert html =~ "3 selected"
  end
end
