defmodule CreatureCrossingWeb.PageControllerTest do
  use CreatureCrossingWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)
    assert response =~ "Welcome to Creature Crossing"
    assert response =~ "Creature Crossing"
    refute response =~ "Phoenix Framework"
    refute response =~ "Peace of mind from prototype to production"
  end
end
