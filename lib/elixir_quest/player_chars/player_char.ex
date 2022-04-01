defmodule ElixirQuest.PlayerChars.PlayerChar do
  @moduledoc """
  The %PlayerChar{} schema.
  """
  use Ecto.Schema
  import Ecto.Changeset
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
  end

  def changeset(pc, attrs) do
    fields = [:name, :level, :experience, :max_hp, :current_hp, :x_pos, :y_pos, :region_id]

    pc
    |> cast(attrs, fields)
    |> validate_required(fields)
  end

  def to_ets(%__MODULE__{
        id: id,
        name: name,
        level: level,
        experience: experience,
        max_hp: max_hp,
        current_hp: current_hp,
        x_pos: x_pos,
        y_pos: y_pos,
        target: target,
        region_id: region_id
      }) do
    {id, __MODULE__, name, level, experience, max_hp, current_hp, x_pos, y_pos, target, region_id}
  end

  def from_ets(
        {id, _, name, level, experience, max_hp, current_hp, x_pos, y_pos, target, region_id}
      ) do
    %__MODULE__{
      id: id,
      name: name,
      level: level,
      experience: experience,
      max_hp: max_hp,
      current_hp: current_hp,
      x_pos: x_pos,
      y_pos: y_pos,
      target: target,
      region_id: region_id
    }
  end
end
