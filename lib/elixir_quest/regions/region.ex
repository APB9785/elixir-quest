defmodule ElixirQuest.Regions.Region do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias ElixirQuest.Mobs.Mob

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "regions" do
    field :raw_map, :binary
    field :name, :string

    has_many :mobs, Mob
  end

  def changeset(region, attrs) do
    region
    |> cast(attrs, [:raw_map, :name])
    |> validate_required([:raw_map, :name])
  end
end
