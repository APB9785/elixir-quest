defmodule ElixirQuest.RegionSupervisor do
  use Supervisor

  alias ElixirQuest.Regions.Region

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      Supervisor.child_spec({Region, "cave"}, id: :cave)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
