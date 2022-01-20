defmodule ElixirQuest.Mobs do
  @moduledoc """
  Functions for working with Mobs.
  """
  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.PlayerChars.PlayerChar

  def seek_targets(region) do
    Enum.map(region.objects, fn
      %Mob{target: target} = mob when is_pid(target) -> seek(mob)
      other_object -> other_object
    end)
  end

  defp seek(%Mob{target: target, location: mob_location} = mob) do
    player_location = GenServer.call(target, :get_location)
    # Extract from PlayerChars.move/3 to get collision detection
  end

  def add_targets(region) do
    # Group the objects first to reduce the complexity of the second reduce
    {player_chars, mobs} =
      Enum.reduce(region.objects, {[], []}, fn
        %PlayerChar{} = pc, {pcs, mobs} -> {[pc | pcs], mobs}
        %Mob{} = mob, {pcs, mobs} -> {pcs, [mob | mobs]}
      end)

    updated_objects =
      Enum.reduce(mobs, player_chars, fn
        %Mob{target: nil} = mob, acc ->
          # Only run the following if the mob doesn't have a target yet
          case Enum.find(player_chars, &check_aggro?(mob, &1)) do
            nil -> [mob | acc]
            %PlayerChar{pid: pc_pid} -> [Map.put(mob, :target, pc_pid) | acc]
          end

        %Mob{} = mob, acc ->
          [mob | acc]
      end)

    Map.put(region, :objects, updated_objects)
  end

  defp check_aggro?(%Mob{} = mob, %PlayerChar{} = player) do
    distance(mob.location, player.location) <= mob.aggro_range
  end

  defp distance({ax, ay}, {bx, by}) do
    x = abs(ax - bx)
    y = abs(ay - by)

    :math.sqrt(x ** 2 + y ** 2)
  end
end
