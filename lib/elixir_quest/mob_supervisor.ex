defmodule ElixirQuest.MobSupervisor do
  use Supervisor

  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.Mobs.Goblin

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      Supervisor.child_spec({Mob, [Goblin, 2, "cave", {2, 2}]}, id: :goblin_1),
      Supervisor.child_spec({Mob, [Goblin, 2, "cave", {13, 3}]}, id: :goblin_2),
      Supervisor.child_spec({Mob, [Goblin, 3, "cave", {2, 8}]}, id: :goblin_3),
      Supervisor.child_spec({Mob, [Goblin, 3, "cave", {13, 8}]}, id: :goblin_4)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
