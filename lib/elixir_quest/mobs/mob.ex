defmodule ElixirQuest.Mobs.Mob do
  @moduledoc """
  The %Mob{} schema.
  """
  use Ecto.Schema
  import Ecto.Query
  alias ElixirQuest.Regions.Region
  alias ElixirQuest.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :string

  schema "mobs" do
    field :name, :string
    field :level, :integer
    field :max_hp, :integer
    field :current_hp, :integer
    field :x_pos, :integer
    field :y_pos, :integer
    field :target, :binary_id
    field :aggro_range, :integer

    belongs_to :region, Region, references: :name, foreign_key: :region_name
  end

  def load(id), do: Repo.get(__MODULE__, id)
end
