defmodule ElixirQuest.Systems.Aggro do
  use ECSx.System,
    period: 5

  alias ElixirQuest.Aspects.Aggro
  alias ElixirQuest.Aspects.Attacking
  alias ElixirQuest.Aspects.Location
  alias ElixirQuest.Aspects.MovementSpeed
  alias ElixirQuest.Aspects.PlayerChar
  alias ElixirQuest.Aspects.Seeking
  alias ElixirQuest.Aspects.Wandering
  alias ElixirQuest.Utils

  @mob_seeking_speed 500

  def run do
    aggro_mobs = Aggro.get_all()
    player_chars = PlayerChar.get_all()

    pcs_with_coords_by_region =
      Enum.reduce(player_chars, %{}, fn %{entity_id: pc_id}, acc ->
        %{region_id: region, x: x, y: y} = Location.get(pc_id)
        Map.update(acc, region, [{pc_id, x, y}], &[{pc_id, x, y} | &1])
      end)

    Enum.each(aggro_mobs, fn %{entity_id: mob_id, aggro_range: aggro_range} ->
      unless Seeking.has_target?(mob_id) do
        look_for_targets(mob_id, aggro_range, pcs_with_coords_by_region)
      end
    end)
  end

  defp look_for_targets(mob_id, aggro_range, pcs_with_coords_by_region) do
    %{region_id: mob_region, x: mob_x, y: mob_y} = Location.get(mob_id)

    case Map.get(pcs_with_coords_by_region, mob_region) do
      nil ->
        # No PCs in this region
        :noop

      local_pcs ->
        case Enum.find(local_pcs, &within_aggro_range?(&1, {mob_x, mob_y}, aggro_range)) do
          nil ->
            # All PCs are out of range
            :noop

          {pc_id, _x, _y} ->
            Wandering.remove(mob_id)
            Seeking.add(entity_id: mob_id, target_id: pc_id)
            Attacking.add(entity_id: mob_id, target_id: pc_id)
            MovementSpeed.update(mob_id, @mob_seeking_speed)
        end
    end
  end

  defp within_aggro_range?({_pc_id, pc_x, pc_y}, {mob_x, mob_y}, aggro_range) do
    Utils.distance({mob_x, mob_y}, {pc_x, pc_y}) <= aggro_range
  end
end
