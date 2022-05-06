defmodule ElixirQuest.Regions.Region do
  @moduledoc """
  The Region schema gives an ID to each region which is used as a foreign key for associating
  with the entities inhabiting the region.  It also contains the map for where the boundaries
  are and the display name for the region.
  """
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
