defmodule CreatureCrossingWeb.GuessWhoLiveTest do
  use CreatureCrossingWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders guess who placeholder", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/guess-who")
    assert html =~ "Guess Who"
    assert html =~ "Coming soon"
  end
end
