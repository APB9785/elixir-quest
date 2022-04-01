defmodule ElixirQuest.RegionSupervisor do
  use Supervisor

  alias ElixirQuest.Collision
  alias ElixirQuest.Components

  def start_link(region) do
    Supervisor.start_link(__MODULE__, region)
  end

  @impl true
  def init(region) do
    load_order = [
      Collision,
      Components
    ]

    children = Enum.map(load_order, &spec(&1, region))

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp spec(module, region) do
    Supervisor.child_spec({Components, region}, id: {Components, region.id})
  end
end
