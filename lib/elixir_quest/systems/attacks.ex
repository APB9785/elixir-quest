defmodule ElixirQuest.Systems.Attacks do
  use ECSx.System

  alias ElixirQuest.Aspects.Attacking
  alias ElixirQuest.Aspects.Cooldown
  alias ElixirQuest.Aspects.Dead
  alias ElixirQuest.Aspects.Equipment
  alias ElixirQuest.Aspects.Health
  alias ElixirQuest.Aspects.Location
  alias ElixirQuest.Aspects.PlayerChar
  alias ElixirQuest.Aspects.Respawn
  alias ElixirQuest.Aspects.Seeking
  alias ElixirQuest.Aspects.Wandering
  alias ElixirQuest.Logs
  alias ElixirQuest.Utils

  def run do
    attacks = Attacking.get_all()

    Enum.each(attacks, fn %{entity_id: attacker_id, target_id: target_id} ->
      cond do
        !Cooldown.ready?(attacker_id, :attack) ->
          :noop

        target_already_dead?(target_id) ->
          unless PlayerChar.has_component?(attacker_id) do
            # Mobs should go back to wandering
            Seeking.remove_component(attacker_id)
            Wandering.add_component(entity_id: attacker_id)
          end

          Attacking.remove_component(attacker_id)

        :otherwise ->
          attempt_attack(attacker_id, target_id)
      end
    end)
  end

  defp target_already_dead?(target_id) do
    Respawn.has_component?(target_id) or Dead.has_component?(target_id)
  end

  defp attempt_attack(attacker_id, target_id) do
    attacker_location = Location.get_component(attacker_id)
    target_location = Location.get_component(target_id)

    %{weapon: %{damage: weapon_dmg, cooldown: weapon_cd, range: weapon_range}} =
      Equipment.get_value(attacker_id, :equipment_map)

    if within_range?(attacker_location, target_location, weapon_range) do
      next_attack = NaiveDateTime.utc_now() |> NaiveDateTime.add(weapon_cd, :millisecond)
      Cooldown.add_component(entity_id: attacker_id, action: :attack, timestamp: next_attack)

      attacker_id
      |> Logs.from_attack(target_id, weapon_dmg)
      |> Logs.broadcast()

      new_hp = Health.decrease_current_hp(target_id, weapon_dmg)

      if new_hp <= 0, do: Dead.add_component(entity_id: target_id)
    end
  end

  defp within_range?(
         %{region_id: region, x: attacker_x, y: attacker_y},
         %{region_id: region, x: target_x, y: target_y},
         range
       ) do
    Utils.distance({attacker_x, attacker_y}, {target_x, target_y}) < range
  end

  defp within_range?(_, _, _), do: false
end
