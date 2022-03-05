defmodule ElixirQuest.Mobs do
  @moduledoc """
  Functions for working with Mobs.
  """
  import Ecto.Query

  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.PlayerChars.PlayerChar
  # alias ElixirQuest.Regions.Region
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

  @doc """
  Get all mob ids from a region.
  """
  def ids_from_region(region_name) do
    Repo.all(
      from m in Mob,
        where: [region: ^region_name],
        select: :id
    )
  end

  defp prepare_mob(mob) do
    # Mobs always spawn at their spawn_location and have full hp.
    Map.merge(mob, %{spawn_location: {mob.x_pos, mob.y_pos}, current_hp: mob.max_hp})
  end

  def wander(%Mob{x_pos: x, y_pos: y, id: id}, collision_server) do
    direction = Enum.random([:north, :south, :east, :west])
    destination = Utils.adjacent_coord({x, y}, direction)

    # TODO: check if destination is blocked; if so try another.
    # However, it could be desirable to not implement this, if we want
    # mobs to spend more time near the walls.

    GenServer.cast(collision_server, {:move, id, {x, y}, destination})
  end

  def seek(%Mob{id: id, target: target_id, x_pos: x, y_pos: y}, region) do
    %PlayerChar{x_pos: pc_x, y_pos: pc_y} = Ets.get!(region.objects, target_id)

    direction = Utils.solve_direction({x, y}, {pc_x, pc_y})
    destination = Utils.adjacent_coord({x, y}, direction)

    GenServer.cast(region.collision_server, {:move, id, {x, y}, destination})
  end

  @doc """
  Checks coordinates around a mob, starting with the adjacents, moving further away until
  the aggro range is reached.
  """
  def aggro(_) do
    nil
  end

  # defp check_aggro?(%Mob{} = mob, %PlayerChar{} = pc) do
  #   Utils.distance({mob.x_pos, mob.y_pos}, {pc.x_pos, pc.y_pos}) <= mob.aggro_range
  # end
end
