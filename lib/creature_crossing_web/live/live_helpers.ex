defmodule CreatureCrossingWeb.LiveHelpers do
  @moduledoc """
  Shared on_mount hooks for all LiveViews.
  """
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:assign_current_path, _params, _session, socket) do
    {:cont,
     attach_hook(socket, :set_current_path, :handle_params, fn _params, uri, socket ->
       path = URI.parse(uri).path
       {:cont, assign(socket, :current_path, path)}
     end)}
  end
end
