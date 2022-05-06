defmodule ElixirQuest.Systems do
  @moduledoc """
  In this module is the logic and frequency for each game system.
  """
  alias ElixirQuest.Components.Action
  alias ElixirQuest.Components.Aggro
  alias ElixirQuest.Components.Dead
  alias ElixirQuest.Components.Equipment
  alias ElixirQuest.Components.Experience
  alias ElixirQuest.Components.Health
  alias ElixirQuest.Components.Image
  alias ElixirQuest.Components.Level
  alias ElixirQuest.Components.Location
  alias ElixirQuest.Components.Name
  alias ElixirQuest.Components.PlayerChar
  alias ElixirQuest.Components.Respawn
  alias ElixirQuest.Components.Seeking
  alias ElixirQuest.Components.Target
  alias ElixirQuest.Components.Wandering
  alias ElixirQuest.Logs
  alias ElixirQuest.Mobs
  alias ElixirQuest.PlayerChars
  alias ElixirQuest.Utils

  Module.register_attribute(__MODULE__, :frequency, accumulate: true)

  @frequency {:seek, 40}
  def seek do
    seeking = Seeking.get_all()

    Enum.each(seeking, fn mob_id ->
      {region_id, x, y} = Location.get(mob_id)
      target_id = Target.get(mob_id)
      {^region_id, target_x, target_y} = Location.get(target_id)

      # TODO: handle if target is no longer in the same region as the seeker

      direction = Utils.solve_direction({x, y}, {target_x, target_y})
      {destination_x, destination_y} = Utils.adjacent_coord({x, y}, direction)

      unless Location.occupied?(region_id, destination_x, destination_y) do
        Location.update(mob_id, destination_x, destination_y)
      end

      # TODO: Look for alternate path if blocked?
    end)
  end

  @frequency {:wander, 50}
  def wander do
    wandering = Wandering.get_all()

    Enum.each(wandering, fn mob_id ->
      {region_id, x, y} = Location.get(mob_id)
      direction = Enum.random([:north, :south, :east, :west])
      {destination_x, destination_y} = Utils.adjacent_coord({x, y}, direction)

      # TODO: check if destination is blocked; if so try another.
      # However, it could be desirable to not implement this, if we want
      # mobs to spend more time near the walls.

      unless Location.occupied?(region_id, destination_x, destination_y) do
        Location.update(mob_id, destination_x, destination_y)
      end
    end)
  end

  @frequency {:aggro, 50}
  def aggro do
    aggro_mobs = Aggro.get_all_with_ids()
    pc_ids = PlayerChar.get_all()

    pcs_with_coords_by_region =
      Enum.reduce(pc_ids, %{}, fn pc_id, acc ->
        {region, x, y} = Location.get(pc_id)
        Map.update(acc, region, [{pc_id, x, y}], &[{pc_id, x, y} | &1])
      end)

    Enum.each(aggro_mobs, fn {mob_id, aggro_range} ->
      case Target.get(mob_id) do
        nil ->
          {mob_region, mob_x, mob_y} = Location.get(mob_id)

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
                  Target.add(mob_id, pc_id)
                  Wandering.remove(mob_id)
                  Seeking.add(mob_id)
              end
          end

        _ ->
          # Mob already has a target
          :noop
      end
    end)
  end

  defp within_aggro_range?({_pc_id, pc_x, pc_y}, {mob_x, mob_y}, aggro_range) do
    Utils.distance({mob_x, mob_y}, {pc_x, pc_y}) <= aggro_range
  end

  @frequency {:death, 10}
  def death do
    dead = Dead.get_all()

    Enum.each(dead, fn id ->
      id
      |> Logs.from_death()
      |> Logs.broadcast()

      Target.remove_from_all(id)
      Location.remove(id)
      Seeking.remove(id)
      Wandering.remove(id)
      Health.remove(id)
      Aggro.remove(id)
      Image.remove(id)
      Name.remove(id)
      Dead.remove(id)

      Respawn.add(id)
    end)
  end

  @frequency {:actions, 5}
  def actions do
    active_actions = Action.get_all_active()
    now = NaiveDateTime.utc_now()

    Enum.each(active_actions, fn {id, :attack, time, true} = action ->
      if NaiveDateTime.compare(now, time) == :gt do
        %{weapon: %{damage: weapon_dmg, cooldown: weapon_cd}} = Equipment.get(id)

        case Target.get(id) do
          nil ->
            Action.reset_cooldown(action)

          target_id ->
            id
            |> Logs.from_attack(target_id, weapon_dmg)
            |> Logs.broadcast()

            new_hp = Health.decrease_current_hp(target_id, weapon_dmg)

            if new_hp <= 0, do: Dead.add(entity_id)

            Action.reset_cooldown(action, weapon_cd)
        end
      end
    end)
  end

  @frequency {:backup_state, 1000}
  def backup_state do
    pc_ids = PlayerChar.get_all()

    Enum.each(pc_ids, fn pc_id ->
      {current_hp, max_hp} = Health.get(pc_id)
      {region, x, y} = Location.get(pc_id)

      attrs = %{
        name: Name.get(pc_id),
        level: Level.get(pc_id),
        experience: Experience.get(pc_id),
        max_hp: max_hp,
        current_hp: current_hp,
        x_pos: x,
        y_pos: y,
        region_id: region
      }

      PlayerChars.save(pc_id, attrs)
    end)
  end

  @frequency {:respawn, 1000}
  def respawn do
    now = NaiveDateTime.utc_now()
    respawns = Respawn.get_all()

    Enum.each(respawns, fn {entity_id, respawn_at} ->
      if NaiveDateTime.compare(respawn_at, now) == :lt do
        entity_id
        |> tap(&Respawn.remove(&1))
        |> Mobs.get!()
        |> Mobs.spawn()
      end
    end)
  end

  # Keep this at the bottom to ensure all frequencies are accumulated
  def frequencies, do: @frequency
end
