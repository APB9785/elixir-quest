defmodule ElixirQuestWeb.Display do
  @moduledoc """
  Functions to display the game state.
  """
  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.PlayerChars.PlayerChar

  @doc """
  Print a given coordinate map, where
    # is a barrier
    + is a mob
    Integers represent the number of PlayerChars at that coordinate
  """
  def print(%{map: map, objects: objects}) do
    mobs = Map.values(objects.mobs)
    players = Map.values(objects.players)

    new_map = Enum.reduce(mobs, map, &Map.put(&2, &1.location, &1))
    new_map = Enum.reduce(players, new_map, &Map.put(&2, &1.location, &1))

    print(new_map, 0, 0, [])
  end

  def print(map, x, y, acc) do
    case Map.get(map, {x, y}) do
      nil when x == 0 ->
        Enum.reverse(acc)

      nil ->
        # print(map, 0, y + 1, ["\n" | acc])
        # currently not using newlines because grid will wrap it automatically
        print(map, 0, y + 1, acc)

      %Mob{} ->
        print(map, x + 1, y, ["+" | acc])

      [] ->
        print(map, x + 1, y, [" " | acc])

      "#" ->
        print(map, x + 1, y, ["#" | acc])

      %PlayerChar{} ->
        print(map, x + 1, y, ["@" | acc])
    end
  end
end
