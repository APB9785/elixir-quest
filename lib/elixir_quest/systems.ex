defmodule ElixirQuest.Systems do
  @moduledoc """
  In this module is the logic and frequency for each game system.
  """
  alias ElixirQuest.Components
  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.Objects
  alias ElixirQuest.ObjectsManager
  alias ElixirQuest.PlayerChars.PlayerChar
  alias ElixirQuest.Utils
  alias ETS.Set, as: Ets

  Module.register_attribute(__MODULE__, :frequency, accumulate: true)

  @frequency {:seek, 40}
  def seek(_) do
    mobs = Objects.get_all_mobs_with_target()

    Enum.each(mobs, fn %Mob{target: target_id, x_pos: x, y_pos: y} = mob ->
      %PlayerChar{x_pos: target_x, y_pos: target_y} = Objects.get_by_id(target_id)

      direction = Utils.solve_direction({x, y}, {target_x, target_y})
      destination = Utils.adjacent_coord({x, y}, direction)

      ObjectsManager.attempt_move(mob, destination)
    end)
  end

  @frequency {:wander, 50}
  def wander(_) do
    mobs = Objects.get_all_mobs_without_target()

    Enum.each(mobs, fn %Mob{x_pos: x, y_pos: y} = mob ->
      direction = Enum.random([:north, :south, :east, :west])
      destination = Utils.adjacent_coord({x, y}, direction)

      # TODO: check if destination is blocked; if so try another.
      # However, it could be desirable to not implement this, if we want
      # mobs to spend more time near the walls.

      ObjectsManager.attempt_move(mob, destination)
    end)
  end

  @frequency {:debug, 500}
  def debug(_) do
    list =
      :objects
      |> Ets.wrap_existing!()
      |> Ets.to_list!()

    Enum.each(list, fn
      {_, :rock, _, _, _, _, _, _, _, _, _} -> :ok
      i -> IO.inspect(i)
    end)

    IO.inspect("-----------")
  end

  @frequency {:aggro, 50}
  def aggro(_) do
    mobs = Objects.get_all_mobs_without_target()

    pcs_by_region =
      Objects.get_all_pcs()
      |> Enum.group_by(& &1.region_id)

    Enum.each(mobs, fn %Mob{x_pos: x, y_pos: y, aggro_range: aggro, region_id: region_id} = mob ->
      local_pcs = Map.get(pcs_by_region, region_id, [])

      case Enum.find(local_pcs, fn pc -> Utils.distance({x, y}, {pc.x_pos, pc.y_pos}) <= aggro end) do
        %PlayerChar{id: target_id} -> ObjectsManager.assign_target(mob, target_id)
        nil -> :ok
      end
    end)
  end

  @frequency {:attack, 20}
  def attack(%{attacking: attacker_map}) do
    new_attacker_map =
      Enum.reduce(attacker_map, %{}, fn
        {attacker_id, 0}, acc ->
          case Objects.do_attack(attacker_id) do
            {:ok, new_cooldown} -> Map.put(acc, attacker_id, new_cooldown)
            {:error, _} -> Map.put(acc, attacker_id, 0)
          end

        {attacker_id, cooldown}, acc ->
          Map.put(acc, attacker_id, cooldown - 1)
      end)

    Components.update_attackers(new_attacker_map)
  end

  # Keep this at the bottom to ensure all frequencies are accumulated
  def frequencies, do: @frequency
end
