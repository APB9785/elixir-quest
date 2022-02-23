defmodule ElixirQuest.Utils do
  @moduledoc """
  Helpers.
  """
  alias ElixirQuest.Regions.Region
  alias ETS.KeyValueSet, as: Ets

  require Logger

  def get_location_contents({x, y}, %Region{objects: objects, location_index: location_index}) do
    case Ets.get!(location_index, {x, y}) do
      nil -> :empty
      :rock -> :rock
      id -> object_by_id(id, objects)
    end
  end

  defp object_by_id(id, objects) do
    case Ets.get!(objects, id) do
      nil -> :empty
      object -> object
    end
  end

  def calculate_nearby_coords({x, y}) do
    for y <- (y - 5)..(y + 5)//1,
        x <- (x - 5)..(x + 5)//1,
        do: {x, y}
  end

  def adjacent_coord({x, y}, direction) do
    case direction do
      :north -> {x, y - 1}
      :south -> {x, y + 1}
      :east -> {x + 1, y}
      :west -> {x - 1, y}
    end
  end
end
