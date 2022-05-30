defmodule ElixirQuest.Systems do
  @moduledoc """
  In this module is the logic and frequency for each game system.

  TODO: split each system into its own module.
  """
  alias ElixirQuest.Components.Aggro
  alias ElixirQuest.Components.Attacking
  alias ElixirQuest.Components.Cooldown
  alias ElixirQuest.Components.Dead
  alias ElixirQuest.Components.Equipment
  # alias ElixirQuest.Components.Experience
  alias ElixirQuest.Components.Health
  alias ElixirQuest.Components.Image
  # alias ElixirQuest.Components.Level
  alias ElixirQuest.Components.Location
  alias ElixirQuest.Components.MovementSpeed
  alias ElixirQuest.Components.Moving
  alias ElixirQuest.Components.Name
  alias ElixirQuest.Components.PlayerChar
  alias ElixirQuest.Components.Respawn
  alias ElixirQuest.Components.Seeking
  alias ElixirQuest.Components.Wandering
  alias ElixirQuest.Logs
  alias ElixirQuest.Mobs
  alias ElixirQuest.PlayerChars
  alias ElixirQuest.Utils

  @mob_seeking_speed 250

  Module.register_attribute(__MODULE__, :frequency, accumulate: true)

  @frequency {:prune_cooldowns, 1}
  def prune_cooldowns do
    cooldowns = Cooldown.get_all()
    now = NaiveDateTime.utc_now()

    Enum.each(cooldowns, fn {entity_id, action, timestamp} ->
      if NaiveDateTime.compare(now, timestamp) == :gt do
        Cooldown.remove(entity_id, action)
      end
    end)
  end

  @frequency {:movement, 1}
  def movement do
    moving = Moving.get_all()

    Enum.each(moving, fn {entity_id, direction} ->
      if Cooldown.ready?(entity_id, :move) do
        {region_id, x, y} = Location.get(entity_id)
        {destination_x, destination_y} = Utils.adjacent_coord({x, y}, direction)

        unless Location.occupied?(region_id, destination_x, destination_y) do
          now = NaiveDateTime.utc_now()
          movement_cooldown = MovementSpeed.get(entity_id)
          next_move_time = NaiveDateTime.add(now, movement_cooldown, :millisecond)
          Location.update(entity_id, region_id, {destination_x, destination_y}, {x, y})
          Cooldown.add(entity_id, :move, next_move_time)
        end
      end
    end)
  end

  @frequency {:seek, 5}
  def seek do
    seeking = Seeking.get_all()

    Enum.each(seeking, fn {mob_id, target_id} ->
      {region_id, x, y} = Location.get(mob_id)
      {^region_id, target_x, target_y} = Location.get(target_id)

      # TODO: handle if target is no longer in the same region as the seeker

      direction = Utils.solve_direction({x, y}, {target_x, target_y})

      # TODO: Look for alternate path if blocked?

      Moving.add(mob_id, direction)
    end)
  end

  @frequency {:wander, 15}
  def wander do
    wandering = Wandering.get_all()

    Enum.each(wandering, fn mob_id ->
      direction = Enum.random([:north, :south, :east, :west])

      # TODO: check if destination is blocked; if so try another.
      # However, it could be desirable to not implement this, if we want
      # mobs to spend more time near the walls.

      Moving.add(mob_id, direction)
    end)
  end

  @frequency {:aggro, 5}
  def aggro do
    aggro_mobs = Aggro.get_all_with_ids()
    pc_ids = PlayerChar.get_all()

    pcs_with_coords_by_region =
      Enum.reduce(pc_ids, %{}, fn pc_id, acc ->
        {region, x, y} = Location.get(pc_id)
        Map.update(acc, region, [{pc_id, x, y}], &[{pc_id, x, y} | &1])
      end)

    Enum.each(aggro_mobs, fn {mob_id, aggro_range} ->
      unless Seeking.has_target?(mob_id) do
        look_for_targets(mob_id, aggro_range, pcs_with_coords_by_region)
      end
    end)
  end

  defp look_for_targets(mob_id, aggro_range, pcs_with_coords_by_region) do
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
            Wandering.remove(mob_id)
            Seeking.add(mob_id, pc_id)
            MovementSpeed.update(mob_id, @mob_seeking_speed)
        end
    end
  end

  defp within_aggro_range?({_pc_id, pc_x, pc_y}, {mob_x, mob_y}, aggro_range) do
    Utils.distance({mob_x, mob_y}, {pc_x, pc_y}) <= aggro_range
  end

  @frequency {:death, 1}
  def death do
    dead = Dead.get_all()

    Enum.each(dead, fn id ->
      id
      |> Logs.from_death()
      |> Logs.broadcast()

      Location.remove(id)
      Seeking.remove(id)
      Wandering.remove(id)
      Health.remove(id)
      Aggro.remove(id)
      Image.remove(id)
      Name.remove(id)
      Dead.remove(id)
      Moving.remove(id)

      Phoenix.PubSub.broadcast(EQPubSub, "entity:#{id}", {:death, id})

      Respawn.add(id)
    end)
  end

  @frequency {:attacks, 1}
  def attacks do
    attacks = Attacking.get_all()

    Enum.each(attacks, fn {attacker_id, target_id} ->
      cond do
        !Cooldown.ready?(attacker_id, :attack) ->
          :noop

        target_already_dead?(target_id) ->
          unless PlayerChar.has_component?(attacker_id) do
            # Mobs should go back to wandering
            Seeking.remove(attacker_id)
            Wandering.add(attacker_id)
          end

          Attacking.remove(attacker_id)

        :otherwise ->
          attempt_attack(attacker_id, target_id)
      end
    end)
  end

  defp target_already_dead?(target_id) do
    Respawn.has_component?(target_id) or Dead.has_component?(target_id)
  end

  defp attempt_attack(attacker_id, target_id) do
    attacker_location = Location.get(attacker_id)
    target_location = Location.get(target_id)

    %{weapon: %{damage: weapon_dmg, cooldown: weapon_cd, range: weapon_range}} =
      Equipment.get(attacker_id)

    if within_range?(attacker_location, target_location, weapon_range) do
      next_attack = NaiveDateTime.utc_now() |> NaiveDateTime.add(weapon_cd, :millisecond)
      Cooldown.add(attacker_id, :attack, next_attack)

      attacker_id
      |> Logs.from_attack(target_id, weapon_dmg)
      |> Logs.broadcast()

      new_hp = Health.decrease_current_hp(target_id, weapon_dmg)

      if new_hp <= 0, do: Dead.add(target_id)
    end
  end

  defp within_range?({region, attacker_x, attacker_y}, {region, target_x, target_y}, range) do
    Utils.distance({attacker_x, attacker_y}, {target_x, target_y}) < range
  end

  defp within_range?(_, _, _), do: false

  @frequency {:backup_state, 250}
  def backup_state do
    pc_ids = PlayerChar.get_all()

    Enum.each(pc_ids, &PlayerChars.save/1)
  end

  @frequency {:respawn, 100}
  def respawn do
    now = NaiveDateTime.utc_now()
    respawns = Respawn.get_all()

    Enum.each(respawns, fn {entity_id, respawn_at} ->
      if NaiveDateTime.compare(respawn_at, now) == :lt do
        entity_id
        |> tap(&Respawn.remove(&1))
        |> tap(&Dead.remove(&1))
        |> Mobs.get!()
        |> Mobs.spawn()
      end
    end)
  end

  # Keep this at the bottom to ensure all frequencies are accumulated
  def frequencies, do: @frequency
end
