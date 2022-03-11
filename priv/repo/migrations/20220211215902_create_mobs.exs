defmodule ElixirQuest.Repo.Migrations.CreateMobs do
  use Ecto.Migration

  def change do
    create table(:mobs) do
      add :name, :string
      add :level, :integer
      add :max_hp, :integer
      add :x_pos, :integer
      add :y_pos, :integer
      add :aggro_range, :integer
      add :region_id, references("regions", type: :binary_id)
    end
  end
end
