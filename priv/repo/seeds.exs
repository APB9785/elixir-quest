# Script for populating the database. You can run it as: `mix run priv/repo/seeds.exs`

alias ElixirQuest.Mobs
alias ElixirQuest.PlayerChars
alias ElixirQuest.Regions

# REGIONS

regions = ["cave"]

Enum.each(regions, fn region_name ->
  path = "static/regions/" <> region_name <> ".txt"

  raw_map =
    :elixir_quest
    |> :code.priv_dir()
    |> Path.join(path)
    |> File.read!()

  Regions.new!(region_name, raw_map)
end)

[cave] = Regions.load_all()

# MOBS

cave_goblins = [
  %{level: 2, x_pos: 2, y_pos: 2},
  %{level: 2, x_pos: 13, y_pos: 3},
  %{level: 3, x_pos: 2, y_pos: 8},
  %{level: 3, x_pos: 13, y_pos: 8}
]

Enum.each(cave_goblins, fn attrs ->
  attrs
  |> Map.merge(%{name: "Goblin", max_hp: 8, aggro_range: 3, region_id: cave.id})
  |> Mobs.new!()
end)

# PLAYER CHARACTER

pc_attrs = %{
  name: "dude",
  region_id: cave.id,
  level: 1,
  experience: 0,
  max_hp: 12,
  current_hp: 12,
  x_pos: 6,
  y_pos: 6
}

PlayerChars.new!(pc_attrs)
