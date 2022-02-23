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
  """
  def print(%{map: map, objects: objects}) do
    mobs = Map.values(objects.mobs)
    players = Map.values(objects.players)

    new_map = Enum.reduce(mobs, map, &Map.put(&2, &1.location, &1))
    new_map = Enum.reduce(players, new_map, &Map.put(&2, &1.location, &1))

    print(new_map, 0, 0, [])
  end
end
