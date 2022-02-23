defmodule ElixirQuest.RegionSupervisor do
  use Supervisor

  alias ElixirQuest.Collision
  alias ElixirQuest.DisplayServer
  alias ElixirQuest.RegionManager
  alias ElixirQuest.Seek

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      Supervisor.child_spec({Collision, "cave"}, id: {Collision, "cave"}),
      Supervisor.child_spec({RegionManager, "cave"}, id: {RegionManager, "cave"}),
      Supervisor.child_spec({DisplayServer, "cave"}, id: {DisplayServer, "cave"}),
      Supervisor.child_spec({Seek, "cave"}, id: {Seek, "cave"})
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
