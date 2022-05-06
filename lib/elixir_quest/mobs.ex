defmodule ElixirQuest.Mobs do
  @moduledoc """
  Functions for working with Mobs.
  """
  import Ecto.Query

  alias ElixirQuest.Components.Aggro
  alias ElixirQuest.Components.Health
  alias ElixirQuest.Components.Image
  alias ElixirQuest.Components.Location
  alias ElixirQuest.Components.Name
  alias ElixirQuest.Components.Wandering
  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.Repo

  def new!(attrs) do
    %Mob{}
    |> Mob.changeset(attrs)
    |> Repo.insert!()
  end

  def get!(mob_id), do: Repo.get!(Mob, mob_id)

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

  @doc """
  Spawn a mob by inserting all its necessary components.
  """
  def spawn(%Mob{id: id} = mob) do
    Location.add(id, mob.region_id, mob.x_pos, mob.y_pos)
    Health.add(id, mob.max_hp, mob.max_hp)
    Wandering.add(id)
    Aggro.add(id, mob.aggro_range)
    Image.add(id, "goblin.png")
    Name.add(id, mob.name)
  end
end
