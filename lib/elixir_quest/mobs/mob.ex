defmodule ElixirQuest.Mobs.Mob do
  @moduledoc """
  The %Mob{} schema.
  """
  use Ecto.Schema
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "mobs" do
    field :name, :string
    field :level, :integer
    field :region, :string
    field :max_hp, :integer
    field :current_hp, :integer
    field :x_pos, :integer
    field :y_pos, :integer
    field :target, :binary_id
    field :aggro_range, :integer
  end

  def load(name) do
    ElixirQuest.Repo.one(from __MODULE__, where: [name: ^name])
  end
end
