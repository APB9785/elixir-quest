defmodule ElixirQuest.PlayerChars do
  @moduledoc """
  Functions for working with player characters.
  """
  import Ecto.Query

  alias ElixirQuest.Accounts.Account
  alias ElixirQuest.Components
  alias ElixirQuest.Components.Experience
  alias ElixirQuest.Components.Health
  alias ElixirQuest.Components.Level
  alias ElixirQuest.Components.Location
  alias ElixirQuest.PlayerChars.PlayerChar, as: PC
  alias ElixirQuest.Regions
  alias ElixirQuest.Repo

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
    {current_hp, max_hp} = Health.get(pc_id)
    {region, x, y} = Location.get(pc_id)

    attrs = %{
      level: Level.get(pc_id),
      experience: Experience.get(pc_id),
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
      Components.despawn_pc(pc)
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
end
