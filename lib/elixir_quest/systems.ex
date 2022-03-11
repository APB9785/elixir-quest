defmodule ElixirQuest.Systems do
  @moduledoc """
  In this module is the logic and frequency for each game system.
  """
  alias ElixirQuest.Collision
  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.Objects
  alias ElixirQuest.PlayerChars.PlayerChar
  alias ElixirQuest.Utils
  alias ETS.KeyValueSet, as: Ets

  Module.register_attribute(__MODULE__, :frequency, accumulate: true)

  @frequency {:seek, 10}
  def seek(%{mobs_with_target: mob_ids, objects: objects, collision_server: collision}) do
    Enum.each(mob_ids, fn id ->
      %Mob{target: target_id, x_pos: x, y_pos: y} = Ets.get!(objects, id)
      %PlayerChar{x_pos: target_x, y_pos: target_y} = Ets.get!(objects, target_id)

      direction = Utils.solve_direction({x, y}, {target_x, target_y})
      destination = Utils.adjacent_coord({x, y}, direction)

      Collision.move(collision, id, {x, y}, destination)
    end)
  end

  @frequency {:wander, 10}
  def wander(%{mobs_without_target: mob_ids, objects: objects, collision_server: collision}) do
    Enum.each(mob_ids, fn id ->
      %Mob{x_pos: x, y_pos: y} = Objects.get(objects, id)
      direction = Enum.random([:north, :south, :east, :west])
      destination = Utils.adjacent_coord({x, y}, direction)

      # TODO: check if destination is blocked; if so try another.
      # However, it could be desirable to not implement this, if we want
      # mobs to spend more time near the walls.

      Collision.move(collision, id, {x, y}, destination)
    end)
  end

  # TODO
  # @frequency {:aggro, 10}
  # def aggro()

  # Keep this at the bottom to ensure all frequencies are accumulated
  def frequencies, do: @frequency
end
