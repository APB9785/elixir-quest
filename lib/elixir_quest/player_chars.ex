defmodule ElixirQuest.PlayerChars do
  @moduledoc """
  Functions for working with player characters.
  """
  import Ecto.Query

  alias ElixirQuest.Accounts.Account
  alias ElixirQuest.Aspects.Equipment
  alias ElixirQuest.Aspects.Experience
  alias ElixirQuest.Aspects.Health
  alias ElixirQuest.Aspects.Image
  alias ElixirQuest.Aspects.Level
  alias ElixirQuest.Aspects.Location
  alias ElixirQuest.Aspects.MovementSpeed
  alias ElixirQuest.Aspects.Name
  alias ElixirQuest.Aspects.PlayerChar
  alias ElixirQuest.Logs
  alias ElixirQuest.Manager
  alias ElixirQuest.PlayerChars.PlayerChar, as: PC
  alias ElixirQuest.Regions
  alias ElixirQuest.Repo
  alias Phoenix.PubSub

  @pc_image_filename "knight.png"
  @pc_base_movement_speed 250
  @weapon_hands_stats %{name: "hands", damage: 1, cooldown: 1000, range: 1.9}

  def create_new(attrs) do
    default_attrs = base_attrs()

    full_attrs = Map.merge(default_attrs, attrs)

    %PC{}
    |> change_pc_registration(full_attrs)
    |> Repo.insert()
  end

  def get_by_account(%Account{id: account_id}) do
    query = from PC, where: [account_id: ^account_id]

    case Repo.all(query) do
      [] -> nil
      [pc] -> pc
    end
  end

  def load!(id), do: Repo.get!(PC, id)

  def save(pc_id) do
    %{current_hp: current_hp, max_hp: max_hp} = Health.get_component(pc_id)
    %{region_id: region, x: x, y: y} = Location.get_component(pc_id)

    attrs = %{
      level: Level.get_value(pc_id, :level),
      experience: Experience.get_value(pc_id, :experience),
      max_hp: max_hp,
      current_hp: current_hp,
      x_pos: x,
      y_pos: y,
      region_id: region
    }

    PC
    |> Repo.get(pc_id)
    |> change_pc_backup(attrs)
    |> Repo.update!()
  end

  def log_out(pc_id) do
    with {:ok, pc} <- save(pc_id) do
      Manager.despawn_pc(pc)
    end
  end

  def change_pc_registration(%PC{} = pc, attrs \\ %{}) do
    PC.registration_changeset(pc, attrs)
  end

  def change_pc_backup(%PC{} = pc, attrs \\ %{}) do
    PC.backup_changeset(pc, attrs)
  end

  def base_attrs do
    %{
      region_id: Regions.get_spawn_region_id(),
      level: 1,
      experience: 0,
      max_hp: 12,
      current_hp: 12,
      x_pos: 6,
      y_pos: 6
    }
  end

  def spawn(%PC{id: id} = pc) do
    Location.add_and_broadcast(id, pc.region_id, pc.x_pos, pc.y_pos)
    Health.add_component(entity_id: id, current_hp: pc.current_hp, max_hp: pc.max_hp)
    PlayerChar.add_component(entity_id: id)
    Level.add_component(entity_id: id, level: pc.level)
    Experience.add_component(entity_id: id, experience: pc.experience)
    Image.add_component(entity_id: id, image_filename: @pc_image_filename)
    Name.add_component(entity_id: id, name: pc.name)
    Equipment.add_component(entity_id: id, equipment_map: %{weapon: @weapon_hands_stats})
    MovementSpeed.add_component(entity_id: id, movement_speed: @pc_base_movement_speed)

    log_entry = Logs.from_spawn(pc.name)
    PubSub.broadcast(EQPubSub, "region:#{pc.region_id}", {:log_entry, log_entry})
  end

  def despawn(%PC{id: id}) do
    Location.remove_and_broadcast(id)

    Health.remove_component(id)
    PlayerChar.remove_component(id)
    Level.remove_component(id)
    Experience.remove_component(id)
    Image.remove_component(id)
    Name.remove_component(id)
    Equipment.remove_component(id)
    MovementSpeed.remove_component(id)
  end
end
