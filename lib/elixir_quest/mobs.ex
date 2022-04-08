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
    Repo.all(
      from(m in Mob,
        select: [:id, :name, :level, :max_hp, :x_pos, :y_pos, :aggro_range, :region_id]
      )
    )
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
end
