defmodule ElixirQuest.Components.Location do
  @moduledoc """
  All entities which physically exist in the game world will have a Location component
  with the id of its region and the x/y coordinates where it are currently located.
  """
  alias ETS.Set, as: Ets

  def initialize_table, do: Ets.new!(name: __MODULE__)

  def add(entity_id, region, x_pos, y_pos) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.put!({entity_id, region, x_pos, y_pos})
  end

  def get(entity_id) do
    table = Ets.wrap_existing!(__MODULE__)

    case Ets.get!(table, entity_id) do
      nil -> nil
      {^entity_id, region, x_pos, y_pos} -> {region, x_pos, y_pos}
    end
  end

  def remove(entity_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.delete!(entity_id)
  end

  @doc """
  Updates the location of an entity to a given coordinate.  Region is unchanged.
  """
  def update(entity_id, x, y) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.update_element!(entity_id, [{3, x}, {4, y}])
  end

  @doc """
  Updates the location of an entity to a given region and coordinate.
  """
  def update(entity_id, region_id, x, y) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.update_element!(entity_id, [{2, region_id}, {3, x}, {4, y}])
  end

  @doc """
  Check a location to see if it is already occupied.
  """
  def occupied?(region_id, x, y) do
    case search(region_id, x, y) do
      nil -> false
      _ -> true
    end
  end

  def search(region_id, x, y) do
    table = Ets.wrap_existing!(__MODULE__)

    case Ets.match!(table, {:"$1", region_id, x, y}, 1) do
      {[], :end_of_table} -> nil
      {[[entity_id]], _} -> entity_id
    end
  end
end
