defmodule CreatureCrossingWeb.MatchGameLiveTest do
  use CreatureCrossingWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders match game placeholder", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/match-game")
    assert html =~ "Match Game"
    assert html =~ "Coming soon"
  end
end
