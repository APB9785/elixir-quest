defmodule ElixirQuest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias ElixirQuest.RegionSupervisor

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      ElixirQuest.Repo,
      # Start the Telemetry supervisor
      ElixirQuestWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: EQPubSub},
      # Start the Endpoint (http/https)
      ElixirQuestWeb.Endpoint,
      # Start a worker by calling: ElixirQuest.Worker.start_link(arg)
      # {ElixirQuest.Worker, arg}
      {Registry, [keys: :unique, name: :region_registry]},
      {RegionSupervisor, [name: RegionSupervisor]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirQuest.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ElixirQuestWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
