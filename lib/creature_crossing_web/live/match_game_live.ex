defmodule CreatureCrossingWeb.MatchGameLive do
  @moduledoc """
  Memory match card game using Animal Crossing imagery.
  """
  use CreatureCrossingWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Match Game")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-center py-12">
      <h1 class="text-4xl font-extrabold tracking-tight">
        Match Game
      </h1>
      <p class="mt-4 text-lg text-base-content/70 max-w-lg mx-auto">
        Coming soon — flip cards and find matching pairs.
      </p>
    </div>
    """
  end
end
