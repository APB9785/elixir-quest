defmodule ElixirQuest.Systems.Seek do
  use ECSx.System,
    period: 5

  alias ElixirQuest.Aspects.Location
  alias ElixirQuest.Aspects.Moving
  alias ElixirQuest.Aspects.Seeking
  alias ElixirQuest.Utils

  def run do
    seeking = Seeking.get_all()

    Enum.each(seeking, fn %{entity_id: mob_id, target_id: target_id} ->
      %{region_id: region_id, x: x, y: y} = Location.get(mob_id)

      case Location.get(target_id) do
        %{region_id: ^region_id, x: target_x, y: target_y} ->
          direction = Utils.solve_direction({x, y}, {target_x, target_y})

          # TODO: Look for alternate path if blocked?

          Moving.add(entity_id: mob_id, direction: direction)

        _ ->
          # target is no longer in the same region as the seeker
          Seeking.remove(mob_id)
      end
    end)
  end
end
