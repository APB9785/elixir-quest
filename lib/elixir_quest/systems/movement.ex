defmodule ElixirQuest.Systems.Movement do
  use ECSx.System

  alias ElixirQuest.Aspects.Cooldown
  alias ElixirQuest.Aspects.Location
  alias ElixirQuest.Aspects.MovementSpeed
  alias ElixirQuest.Aspects.Moving
  alias ElixirQuest.Utils

  def run do
    moving = Moving.get_all()

    Enum.each(moving, fn %{entity_id: entity_id, direction: direction} ->
      if Cooldown.ready?(entity_id, :move) do
        %{region_id: region_id, x: x, y: y} = Location.get_component(entity_id)
        {destination_x, destination_y} = Utils.adjacent_coord({x, y}, direction)

        unless Location.occupied?(region_id, destination_x, destination_y) do
          now = NaiveDateTime.utc_now()
          movement_cooldown = MovementSpeed.get_value(entity_id, :movement_speed)
          next_move_time = NaiveDateTime.add(now, movement_cooldown, :millisecond)
          Location.update(entity_id, region_id, {destination_x, destination_y}, {x, y})
          Cooldown.add_component(entity_id: entity_id, action: :move, timestamp: next_move_time)
        end
      end
    end)
  end
end
