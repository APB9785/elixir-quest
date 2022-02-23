defmodule ElixirQuest.Repo.Migrations.CreatePlayerChars do
  use Ecto.Migration

  def change do
    create table(:player_chars) do
      add :name, :string
      add :level, :integer
      add :experience, :integer
      add :region, :string
      add :max_hp, :integer
      add :current_hp, :integer
      add :x_pos, :integer
      add :y_pos, :integer
    end
  end
end
