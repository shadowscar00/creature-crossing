defmodule CreatureCrossingWeb.GuessWhoLive do
  @moduledoc """
  Guess Who game using Animal Crossing NH villagers.
  """
  use CreatureCrossingWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Guess Who")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-center py-12">
      <h1 class="text-4xl font-extrabold tracking-tight">
        Guess Who
      </h1>
      <p class="mt-4 text-lg text-base-content/70 max-w-lg mx-auto">
        Coming soon — guess the villager before your opponent does.
      </p>
    </div>
    """
  end
end
