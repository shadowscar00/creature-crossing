defmodule CreatureCrossingWeb.CreatureCrossingLiveTest do
  use CreatureCrossingWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders critter tool placeholder", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/creature-crossing")
    assert html =~ "Critter Tool"
    assert html =~ "Coming soon"
  end

  test "sets page title", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/creature-crossing")
    assert html =~ "Critter Tool"
  end
end
