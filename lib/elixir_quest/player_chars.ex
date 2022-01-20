defmodule ElixirQuest.PlayerChars do
  @moduledoc """
  Functions for working with player characters.
  """
  alias ElixirQuest.PlayerChars.PlayerChar
  alias ElixirQuest.Regions

  def move(region, %PlayerChar{} = player, direction) do
    new_location = adjacent_coord(player.location, direction)

    cond do
      MapSet.member?(region.boundaries, new_location) ->
        region

      Enum.any?(region.objects, fn object -> object.location == new_location end) ->
        region

      :otherwise ->
        updated_player = Map.put(player, :location, new_location)
        Regions.update_objects(region, updated_player)
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
end
