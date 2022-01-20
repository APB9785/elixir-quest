defmodule ElixirQuest.Regions do
  @moduledoc """
  Functions for working with Regions.
  """
  alias ElixirQuest.Mobs.Goblin
  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.PlayerChars.PlayerChar

  @doc """
  This is called by an object when spawned, and will send the object's pid to
  the Region.
  """
  def spawn_in(region_name, object) when is_binary(region_name) do
    [{pid, _}] = Registry.lookup(:region_registry, region_name)
    spawn_in(pid, object)
  end

  def spawn_in(pid, object) when is_pid(pid) do
    GenServer.cast(pid, {:entry, object})
  end

  def map(region_name) do
    path = "static/regions/" <> region_name <> ".txt"

    :code.priv_dir(:elixir_quest)
    |> Path.join(path)
    |> File.read!()
    |> String.graphemes()
    |> parse_txt()
  end

  defp parse_txt(map, x \\ 0, y \\ 0, acc \\ %{})

  defp parse_txt([], _, _, acc), do: acc

  defp parse_txt(["\n" | rest], _x, y, acc) do
    parse_txt(rest, 0, y + 1, acc)
  end

  defp parse_txt([" " | rest], x, y, acc) do
    new_acc = Map.put(acc, {x, y}, [])
    parse_txt(rest, x + 1, y, new_acc)
  end

  defp parse_txt(["#" | rest], x, y, acc) do
    new_acc = Map.put(acc, {x, y}, "#")
    parse_txt(rest, x + 1, y, new_acc)
  end

  def boundaries(region_map) do
    Enum.reduce(region_map, MapSet.new(), fn {coord, content}, acc ->
      if content == "#", do: MapSet.put(acc, coord), else: acc
    end)
  end

  def spawn_mobs("cave") do
    to_spawn = [
      %{type: Goblin, level: 2, location: {2, 2}},
      %{type: Goblin, level: 2, location: {13, 3}},
      %{type: Goblin, level: 3, location: {2, 8}},
      %{type: Goblin, level: 3, location: {13, 8}}
    ]

    Enum.map(to_spawn, fn %{type: type, level: level, location: location} ->
      mob = type.new(level, location)
      IO.puts("Region cave: Level #{level} #{mob.name} spawned")
      mob
    end)
  end

  # Given an updated %PlayerChar{}, replace the existing one
  def update_objects(%{objects: objects} = region, %PlayerChar{} = player) do
    objects = Enum.reject(objects, fn object -> object.name == player.name end)

    Map.put(region, :objects, [player | objects])
  end

  # Sorts the objects into {[player_chars], [mobs]} so the aggro check
  # is O(mn) instead of O({m + n}^2)
  def separate_objects(%{objects: objects}) do
    Enum.reduce(objects, {[], []}, fn
      %PlayerChar{} = pc, {pcs, mobs} -> {[pc | pcs], mobs}
      %Mob{} = mob, {pcs, mobs} -> {pcs, [mob | mobs]}
    end)
  end
end
