defmodule CreatureCrossingWeb.HomeLive do
  @moduledoc """
  Landing page for Creature Crossing.
  """
  use CreatureCrossingWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-center py-12">
      <h1 class="text-4xl font-extrabold tracking-tight">
        Welcome to Creature Crossing
      </h1>
      <p class="mt-4 text-lg text-base-content/70 max-w-lg mx-auto">
        Your cozy Animal Crossing companion — tools and games powered by the world of AC.
      </p>
    </div>
    """
  end
end
