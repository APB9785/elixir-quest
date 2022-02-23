defmodule ElixirQuest.Repo.Migrations.CreateRegions do
  use Ecto.Migration

  def change do
    create table(:regions) do
      add :name, :string
      add :raw_map, :text
    end
  end
end
