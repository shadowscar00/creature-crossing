defmodule CreatureCrossingWeb.PageController do
  use CreatureCrossingWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
