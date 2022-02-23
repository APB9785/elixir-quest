# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ElixirQuest.Repo.insert!(%ElixirQuest.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias ElixirQuest.Mobs.Goblin
alias ElixirQuest.PlayerChars.PlayerChar
alias ElixirQuest.Regions.Region
alias ElixirQuest.Repo

# REGION MAPS

regions = ["cave"]

Enum.each(regions, fn region_name ->
  path = "static/regions/" <> region_name <> ".txt"

  raw_map =
    :elixir_quest
    |> :code.priv_dir()
    |> Path.join(path)
    |> File.read!()

  region = Region.new(region_name, raw_map)
  Repo.insert!(region)
end)

# MOBS

cave_goblins = [
  {2, "cave", {2, 2}},
  {2, "cave", {13, 3}},
  {3, "cave", {2, 8}},
  {3, "cave", {13, 8}}
]

Enum.each(cave_goblins, fn {level, region, location} ->
  mob = Goblin.new(level, region, location)
  Repo.insert!(mob)
end)

# PLAYER CHARACTERS

player_chars = [
  {"dude", {6, 6}}
]

Enum.each(player_chars, fn {name, location} ->
  pc = PlayerChar.new(name, location)
  Repo.insert!(pc)
end)
