defmodule ElixirQuest.Regions.Region do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Query
  alias ElixirQuest.Mobs.Mob

  @primary_key {:name, :string, autogenerate: false}
  @foreign_key_type :binary_id

  schema "regions" do
    field :raw_map, :binary

    has_many :mobs, Mob
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

  def load_with_mobs(name) do
    ElixirQuest.Repo.one(from __MODULE__, where: [name: ^name], preload: [:mobs])
  end
end
