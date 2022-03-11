defmodule ElixirQuest.RealmSupervisor do
  use Supervisor

  alias ElixirQuest.Regions
  alias ElixirQuest.RegionSupervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [])
  end

  @impl true
  def init(_) do
    regions = Regions.load_all()

    children = Enum.map(regions, &spec/1)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp spec(region) do
    Supervisor.child_spec({RegionSupervisor, region}, id: {RegionSupervisor, region.id})
  end
end
