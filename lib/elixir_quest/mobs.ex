defmodule ElixirQuest.Mobs do
  @moduledoc """
  Functions for working with Mobs.
  """
  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.PlayerChars.PlayerChar
  alias ElixirQuest.Regions

  @doc """
  Each mob either moves towards its target, or randomly wanders.
  """
  def move(%{objects: %{mobs: mobs}} = region) do
    mobs
    |> Map.values()
    |> Enum.reduce(region, &seek_or_wander/2)
  end

  @directions [:north, :east, :south, :west]

  defp seek_or_wander(%Mob{target: nil} = mob, region) do
    direction = Enum.random(@directions)

    Regions.move_object(region, mob, direction)
  end

  defp seek_or_wander(%Mob{target: target_id, location: mob_location} = mob, region) do
    player_location =
      region.objects.players
      |> Map.fetch!(target_id)
      |> Map.fetch!(:location)

    direction = solve_direction(mob_location, player_location)

    Regions.move_object(region, mob, direction)
  end

  defp solve_direction({mob_x, mob_y}, {player_x, player_y}) do
    dx = mob_x - player_x
    dy = mob_y - player_y

    if abs(dx) > abs(dy) do
      if dx > 0, do: :west, else: :east
    else
      if dy > 0, do: :north, else: :south
    end
  end

  @doc """
  Iterates over each mob to check if it is close enough to a player to target them.
  """
  def aggro(%{objects: %{mobs: mobs_map, players: players_map}} = region) do
    players = Map.values(players_map)

    updated_mobs_map =
      Map.new(mobs_map, fn {mob_id, mob} ->
        if is_nil(mob.target) do
          # Only need to check for a target if the mob doesn't already have one
          case Enum.find(players, &check_aggro?(mob, &1)) do
            nil -> {mob_id, mob}
            %PlayerChar{id: player_id} -> {mob_id, Map.put(mob, :target, player_id)}
          end
        else
          {mob_id, mob}
        end
      end)

    put_in(region.objects.mobs, updated_mobs_map)
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
