defmodule ElixirQuest.Regions do
  @moduledoc """
  Functions for working with Regions.
  """
  alias ElixirQuest.Mobs.Goblin
  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.PlayerChars.PlayerChar

  @doc """
  This is called by an object when spawned, and will send the object's pid to the Region.
  """
  def spawn_in(region_name, object) when is_binary(region_name) do
    [{pid, _}] = Registry.lookup(:region_registry, region_name)
    spawn_in(pid, object)
  end

  def spawn_in(pid, object) when is_pid(pid) do
    GenServer.cast(pid, {:entry, object})
  end

  @doc """
  This will read the map file for a region and parse it into a map, where
  keys are coordinates ({0, 0} at top left), and values are:
    "#" for boundaries
    [] for an open space
  """
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

  @doc """
  Creates a MapSet of map boundaries and impassable environment spaces.
  """
  def boundaries(region_map) do
    Enum.reduce(region_map, MapSet.new(), fn {coord, content}, acc ->
      if content == "#", do: MapSet.put(acc, coord), else: acc
    end)
  end

  @doc """
  Temporary spawner until we have a DB from which to load.
  """
  def spawn_mobs("cave") do
    to_spawn = [
      %{id: 1, type: Goblin, level: 2, location: {2, 2}},
      %{id: 2, type: Goblin, level: 2, location: {13, 3}},
      %{id: 3, type: Goblin, level: 3, location: {2, 8}},
      %{id: 4, type: Goblin, level: 3, location: {13, 8}}
    ]

    Enum.reduce(to_spawn, %{}, fn %{id: id, type: type, level: level, location: location}, acc ->
      mob = type.new(id, level, location)
      Map.put(acc, id, mob)
    end)
  end

  @doc """
  Attempt to move an object.  If the object is blocked, this will fail silently.
  Either way, this returns the updated region state.
  """
  def move_object(region, object, direction) do
    new_location = adjacent_coord(object.location, direction)
    mobs = Map.values(region.objects.mobs)
    players = Map.values(region.objects.players)

    cond do
      MapSet.member?(region.boundaries, new_location) ->
        # Collision with map boundary
        region

      Enum.any?(mobs, &(&1.location == new_location)) ->
        # Collision with a mob
        region

      Enum.any?(players, &(&1.location == new_location)) ->
        # Collision with a player
        region

      :otherwise ->
        # No collision detected, go ahead with movement
        updated_object = Map.put(object, :location, new_location)
        update_objects(region, updated_object)
    end
  end

  defp adjacent_coord({x, y}, direction) do
    case direction do
      :north -> {x, y - 1}
      :south -> {x, y + 1}
      :east -> {x + 1, y}
      :west -> {x - 1, y}
    end
  end

  # Given an updated PC/mob, replace the existing one
  defp update_objects(region, object) do
    case object do
      %PlayerChar{id: id} ->
        update_in(region.objects.players, &Map.put(&1, id, object))

      %Mob{id: id} ->
        update_in(region.objects.mobs, &Map.put(&1, id, object))
    end
  end
end
