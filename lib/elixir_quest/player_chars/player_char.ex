defmodule ElixirQuest.PlayerChars.PlayerChar do
  @moduledoc """
  The PlayerChar schema persists player data, which is fetched when the PC is spawned.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias ElixirQuest.Accounts.Account
  alias ElixirQuest.Regions.Region

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "player_chars" do
    field :name, :string
    field :level, :integer
    field :experience, :integer
    field :max_hp, :integer
    field :current_hp, :integer
    field :x_pos, :integer
    field :y_pos, :integer

    field :target, :binary_id, virtual: true

    belongs_to :region, Region
    belongs_to :account, Account
  end

  def registration_changeset(pc, attrs) do
    fields = [
      :name,
      :level,
      :experience,
      :max_hp,
      :current_hp,
      :x_pos,
      :y_pos,
      :region_id,
      :account_id
    ]

    pc
    |> cast(attrs, fields)
    |> validate_required(fields)
    |> validate_name()
  end

  defp validate_name(changeset) do
    changeset
    |> validate_length(:name, min: 2, max: 24)
    |> unsafe_validate_unique(:name, ElixirQuest.Repo)
    |> unique_constraint(:name)
  end

  def backup_changeset(pc, attrs) do
    fields = [
      :level,
      :experience,
      :max_hp,
      :current_hp,
      :x_pos,
      :y_pos,
      :region_id
    ]

    pc
    |> cast(attrs, fields)
    |> validate_required(fields)
  end
end
