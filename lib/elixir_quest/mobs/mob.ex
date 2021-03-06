defmodule ElixirQuest.Mobs.Mob do
  @moduledoc """
  The Mob schema represents the initial values for each mob when it spawns.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias ElixirQuest.Regions.Region

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "mobs" do
    field :name, :string
    field :level, :integer
    field :max_hp, :integer
    field :x_pos, :integer
    field :y_pos, :integer
    field :aggro_range, :integer

    belongs_to :region, Region
  end

  def changeset(mob, attrs) do
    fields = [:name, :level, :max_hp, :x_pos, :y_pos, :aggro_range, :region_id]

    mob
    |> cast(attrs, fields)
    |> validate_required(fields)
  end
end
