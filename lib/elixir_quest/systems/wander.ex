defmodule ElixirQuest.Systems.Wander do
  use ECSx.System,
    period: 15

  alias ElixirQuest.Aspects.Moving
  alias ElixirQuest.Aspects.Wandering

  def run do
    wandering = Wandering.get_all()

    Enum.each(wandering, fn %{entity_id: mob_id} ->
      direction = Enum.random([:north, :south, :east, :west])

      # TODO: check if destination is blocked; if so try another.
      # However, it could be desirable to not implement this, if we want
      # mobs to spend more time near the walls.

      Moving.add(entity_id: mob_id, direction: direction)
    end)
  end
end
