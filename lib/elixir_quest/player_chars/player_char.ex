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
end
