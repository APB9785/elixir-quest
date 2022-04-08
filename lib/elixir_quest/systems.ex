defmodule ElixirQuest.Systems do
  @moduledoc """
  In this module is the logic and frequency for each game system.
  """
  alias ElixirQuest.Components
  alias ElixirQuest.Utils

  Module.register_attribute(__MODULE__, :frequency, accumulate: true)

  @frequency {:seek, 40}
  def seek do
    seeking = Components.get_all(:seeking)

    Enum.each(seeking, fn {mob_id} ->
      {region_id, {x, y}} = Components.get(:location, mob_id)
      target_id = Components.get(:target, mob_id)
      {^region_id, {target_x, target_y}} = Components.get(:location, target_id)

      # TODO: handle if target is no longer in the same region as the seeker

      direction = Utils.solve_direction({x, y}, {target_x, target_y})
      destination = Utils.adjacent_coord({x, y}, direction)

      unless Components.location_occupied?(region_id, destination) do
        Components.update_location(mob_id, destination)
      end

      # TODO: Look for alternate path if blocked?
    end)
  end

  @frequency {:wander, 50}
  def wander do
    wandering = Components.get_all(:wandering)

    Enum.each(wandering, fn {mob_id} ->
      {region_id, {x, y}} = Components.get(:location, mob_id)
      direction = Enum.random([:north, :south, :east, :west])
      destination = Utils.adjacent_coord({x, y}, direction)

      # TODO: check if destination is blocked; if so try another.
      # However, it could be desirable to not implement this, if we want
      # mobs to spend more time near the walls.

      unless Components.location_occupied?(region_id, destination) do
        Components.update_location(mob_id, destination)
      end
    end)
  end

  @frequency {:aggro, 50}
  def aggro do
    mobs = Components.get_all(:aggro)

    pcs_with_coords_by_region =
      :player_chars
      |> Components.get_all()
      |> Enum.reduce(%{}, fn {pc_id}, acc ->
        {region, location} = Components.get(:location, pc_id)
        Map.update(acc, region, [{pc_id, location}], &[{pc_id, location} | &1])
      end)

    Enum.each(mobs, fn {mob_id, aggro_range} ->
      case Components.get(:target, mob_id) do
        nil ->
          {mob_region, mob_location} = Components.get(:location, mob_id)

          case Map.get(pcs_with_coords_by_region, mob_region) do
            nil ->
              # No PCs in this region
              :noop

            local_pcs ->
              case Enum.find(local_pcs, &within_aggro_range?(&1, mob_location, aggro_range)) do
                nil ->
                  # All PCs are out of range
                  :noop

                {pc_id, _} ->
                  Components.add(:target, mob_id, pc_id)
                  Components.remove(:wandering, mob_id)
                  Components.add(:seeking, mob_id)
              end
          end

        _ ->
          # Mob already has a target
          :noop
      end
    end)
  end

  defp within_aggro_range?({_pc_id, pc_location}, mob_location, aggro_range) do
    Utils.distance(mob_location, pc_location) <= aggro_range
  end

  @frequency {:actions, 10}
  def actions do
    cooldowns = Components.get_all(:cooldown)
    now = NaiveDateTime.utc_now()

    Enum.each(cooldowns, fn {{id, :attack}, time} = cooldown ->
      if NaiveDateTime.compare(now, time) == :gt do
        %{weapon: %{damage: weapon_dmg, cooldown: weapon_cd}} = Components.get(:equipped, id)
        target_id = Components.get(:target, id)

        Components.decrease_current_hp(target_id, weapon_dmg)
        Components.reset_cooldown(cooldown, weapon_cd)
      end
    end)
  end

  # Keep this at the bottom to ensure all frequencies are accumulated
  def frequencies, do: @frequency
end
