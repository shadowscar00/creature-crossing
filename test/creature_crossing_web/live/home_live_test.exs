defmodule CreatureCrossingWeb.HomeLiveTest do
  use CreatureCrossingWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders home page", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")
    assert html =~ "Welcome to Creature Crossing"
    refute html =~ "Phoenix Framework"
  end

  test "home page has navbar with Nookphone", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")
    assert html =~ "nookphone-btn"
    assert html =~ "Creature Crossing"
  end
end
