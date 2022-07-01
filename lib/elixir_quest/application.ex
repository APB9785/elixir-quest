defmodule ElixirQuest.Application do
  @moduledoc false
  use Application

  alias ElixirQuest.Manager

  @impl true
  def start(_type, _args) do
    children = [
      ElixirQuest.Repo,
      ElixirQuestWeb.Telemetry,
      {Phoenix.PubSub, name: EQPubSub},
      Manager,
      ElixirQuestWeb.Endpoint
    ]

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
