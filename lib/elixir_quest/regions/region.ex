defmodule ElixirQuest.Regions.Region do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "regions" do
    field :name, :string
    field :raw_map, :binary

    # These will be ETS sets
    field :objects, :any, virtual: true
    field :location_index, :any, virtual: true

    # These will be pids
    field :manager, :any, virtual: true
    field :collision_server, :any, virtual: true
  end

  def new(name, raw_map) do
    %__MODULE__{
      name: name,
      raw_map: raw_map
    }
  end

  def load(name) do
    ElixirQuest.Repo.one(from __MODULE__, where: [name: ^name])
  end
end
