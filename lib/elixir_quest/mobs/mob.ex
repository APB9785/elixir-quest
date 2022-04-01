defmodule ElixirQuest.Mobs.Mob do
  @moduledoc """
  The %Mob{} schema.
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
    field :target, :binary_id, virtual: true
    field :current_hp, :integer, virtual: true

    belongs_to :region, Region
  end

  def changeset(mob, attrs) do
    fields = [:name, :level, :max_hp, :x_pos, :y_pos, :aggro_range, :region_id]

    mob
    |> cast(attrs, fields)
    |> validate_required(fields)
  end

  def to_ets(%__MODULE__{
        id: id,
        name: name,
        level: level,
        max_hp: max_hp,
        current_hp: current_hp,
        x_pos: x_pos,
        y_pos: y_pos,
        aggro_range: aggro_range,
        target: target,
        region_id: region_id
      }) do
    {id, __MODULE__, name, level, aggro_range, max_hp, current_hp, x_pos, y_pos, target,
     region_id}
  end

  def from_ets(
        {id, _, name, level, aggro_range, max_hp, current_hp, x_pos, y_pos, target, region_id}
      ) do
    %__MODULE__{
      id: id,
      name: name,
      level: level,
      max_hp: max_hp,
      current_hp: current_hp,
      x_pos: x_pos,
      y_pos: y_pos,
      aggro_range: aggro_range,
      target: target,
      region_id: region_id
    }
  end
end
