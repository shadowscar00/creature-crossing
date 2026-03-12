defmodule CreatureCrossingWeb.CreatureCrossingLive do
  @moduledoc """
  Creature Crossing critter tool — cross-reference missing critters
  to find the optimal catching time.
  """
  use CreatureCrossingWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Critter Tool")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-center py-12">
      <h1 class="text-4xl font-extrabold tracking-tight">
        Critter Tool
      </h1>
      <p class="mt-4 text-lg text-base-content/70 max-w-lg mx-auto">
        Coming soon — find the best time to catch your missing critters.
      </p>
    </div>
    """
  end
end
