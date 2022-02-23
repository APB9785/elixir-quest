defmodule ElixirQuest.Mobs do
  @moduledoc """
  Functions for working with Mobs.
  """
  import Ecto.Query

  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.PlayerChars.PlayerChar
  alias ElixirQuest.Regions.Region
  alias ElixirQuest.Repo
  alias ElixirQuest.Utils
  alias ETS.KeyValueSet, as: Ets

  @doc """
  Loads all mobs.
  """
  def load_from_region(region_name) do
    from(m in Mob,
      where: [region: ^region_name],
      select: [:id, :name, :level, :max_hp, :x_pos, :y_pos, :aggro_range, :region]
    )
    |> Repo.all()
    |> Enum.map(&prepare_mob/1)
  end

  defp prepare_mob(mob) do
    # Mobs always spawn at their spawn_location and have full hp.
    Map.merge(mob, %{spawn_location: {mob.x_pos, mob.y_pos}, current_hp: mob.max_hp})
  end

  def seek_or_wander(mob_id, %Region{objects: objects, collision_server: collision} = region) do
    case Ets.get!(objects, mob_id) do
      %Mob{target: nil, x_pos: x, y_pos: y} ->
        # Wander
        direction = Enum.random([:north, :south, :east, :west])
        destination = Utils.adjacent_coord({x, y}, direction)
        # TODO: check if destination is blocked; if so try another
        GenServer.cast(collision, {:move, mob_id, {x, y}, destination})

      %Mob{target: pc_id, x_pos: x, y_pos: y} ->
        # Seek
        %PlayerChar{x_pos: pc_x, y_pos: pc_y} = Ets.get!(objects, pc_id)
        direction = solve_direction({x, y}, {pc_x, pc_y})
        destination = Utils.adjacent_coord({x, y}, direction)
        GenServer.cast(collision, {:move, mob_id, {x, y}, destination})
    end
  end

  defp solve_direction({mob_x, mob_y}, {pc_x, pc_y}) do
    dx = mob_x - pc_x
    dy = mob_y - pc_y

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

  defp check_aggro?(%Mob{} = mob, %PlayerChar{} = pc) do
    distance({mob.x_pos, mob.y_pos}, {pc.x_pos, pc.y_pos}) <= mob.aggro_range
  end

  defp distance({ax, ay}, {bx, by}) do
    x = abs(ax - bx)
    y = abs(ay - by)

    :math.sqrt(x ** 2 + y ** 2)
  end
end
