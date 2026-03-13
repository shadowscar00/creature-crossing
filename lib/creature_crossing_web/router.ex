defmodule CreatureCrossingWeb.Router do
  use CreatureCrossingWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CreatureCrossingWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  live_session :default,
    on_mount: [{CreatureCrossingWeb.LiveHelpers, :assign_current_path}],
    layout: {CreatureCrossingWeb.Layouts, :app} do
    scope "/", CreatureCrossingWeb do
      pipe_through :browser

      live "/", HomeLive
      live "/creature-crossing", CreatureCrossingLive
      live "/guess-who", GuessWhoLive
      live "/match-game", MatchGameLive
      live "/data-test", DataTestLive
      live "/dev", DevLive
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", CreatureCrossingWeb do
  #   pipe_through :api
  # end
end
