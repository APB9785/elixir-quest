defmodule ElixirQuest.RegionSupervisor do
  use Supervisor

  alias ElixirQuest.Collision
  alias ElixirQuest.Components

  def start_link(region_name) do
    Supervisor.start_link(__MODULE__, region_name)
  end

  @impl true
  def init(region_name) do
    load_order = [
      Collision,
      Components
    ]

    children = Enum.map(load_order, &spec(&1, region_name))

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp spec(module, region_name) do
    Supervisor.child_spec({module, region_name}, id: {module, region_name})
  end
end
