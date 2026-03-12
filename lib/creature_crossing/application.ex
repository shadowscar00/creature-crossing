defmodule CreatureCrossing.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CreatureCrossingWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:creature_crossing, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CreatureCrossing.PubSub},
      # Start a worker by calling: CreatureCrossing.Worker.start_link(arg)
      # {CreatureCrossing.Worker, arg},
      # Start to serve requests, typically the last entry
      CreatureCrossingWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CreatureCrossing.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CreatureCrossingWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
