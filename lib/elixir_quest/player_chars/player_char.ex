defmodule ElixirQuest.PlayerChars.PlayerChar do
  @moduledoc """
  The %PlayerChar{} schema.
  """
  use Ecto.Schema
  import Ecto.Query
  alias ElixirQuest.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "player_chars" do
    field :name, :string
    field :level, :integer
    field :experience, :integer
    field :region, :string
    field :max_hp, :integer
    field :current_hp, :integer
    field :x_pos, :integer
    field :y_pos, :integer
    field :target, :binary_id, virtual: true
  end

  def new(name, {x, y}) do
    %__MODULE__{
      name: name,
      level: 1,
      experience: 0,
      region: "cave",
      max_hp: 12,
      current_hp: 12,
      x_pos: x,
      y_pos: y,
      target: nil
    }
  end

  def load(id), do: Repo.get(__MODULE__, id)

  # Temporary id lookup until accounts are setup (then id will be read from accounts table)
  def name_to_id(name) do
    Repo.one(
      from pc in __MODULE__,
        where: pc.name == ^name,
        select: pc.id
    )
  end
end
