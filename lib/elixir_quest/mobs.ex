defmodule ElixirQuest.Mobs do
  @moduledoc """
  Functions for working with Mobs.
  """
  import Ecto.Query

  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.Repo

  def new!(attrs) do
    %Mob{}
    |> Mob.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Loads all mobs.
  """
  def load_all do
    from(m in Mob,
      select: [:id, :name, :level, :max_hp, :x_pos, :y_pos, :aggro_range, :region_id]
    )
    |> Repo.all()
    |> Enum.map(&prepare_mob/1)
  end

  @doc """
  Get all mob ids from a region.
  """
  def ids_from_region(region_id) do
    Repo.all(
      from m in Mob,
        where: m.region_id == ^region_id,
        select: m.id
    )
  end

  defp prepare_mob(mob) do
    # Mobs always spawn at their spawn_location and have full hp.
    Map.merge(mob, %{spawn_location: {mob.x_pos, mob.y_pos}, current_hp: mob.max_hp})
  end

  # @doc """
  # Checks coordinates around a mob, starting with the adjacents, moving further away until
  # the aggro range is reached.
  # """
  # def aggro(_) do
  #   nil
  # end

  # defp check_aggro?(%Mob{} = mob, %PlayerChar{} = pc) do
  #   Utils.distance({mob.x_pos, mob.y_pos}, {pc.x_pos, pc.y_pos}) <= mob.aggro_range
  # end
end
