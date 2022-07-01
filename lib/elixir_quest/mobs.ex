defmodule ElixirQuest.Mobs do
  @moduledoc """
  Functions for working with Mobs.
  """
  import Ecto.Query

  alias ElixirQuest.Aspects.Aggro
  alias ElixirQuest.Aspects.Equipment
  alias ElixirQuest.Aspects.Health
  alias ElixirQuest.Aspects.Image
  alias ElixirQuest.Aspects.Location
  alias ElixirQuest.Aspects.MovementSpeed
  alias ElixirQuest.Aspects.Name
  alias ElixirQuest.Aspects.Wandering
  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.Repo

  @default_mob_image_filename "goblin.png"
  @mob_wandering_speed 1000
  @goblin_weapon_stats %{name: "hands", damage: 1, cooldown: 4000, range: 1.9}

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
  def spawn_mob(%Mob{id: id} = mob) do
    Location.add_and_broadcast(id, mob.region_id, mob.x_pos, mob.y_pos)
    Health.add_component(entity_id: id, current_hp: mob.max_hp, max_hp: mob.max_hp)
    Wandering.add_component(entity_id: id)
    Aggro.add_component(entity_id: id, aggro_range: mob.aggro_range)
    Image.add_component(entity_id: id, image_filename: @default_mob_image_filename)
    Name.add_component(entity_id: id, name: mob.name)
    MovementSpeed.add_component(entity_id: id, movement_speed: @mob_wandering_speed)
    Equipment.add_component(entity_id: id, equipment_map: %{weapon: @goblin_weapon_stats})
  end

  def spawn_all do
    Enum.each(load_all(), &spawn_mob/1)
  end
end
