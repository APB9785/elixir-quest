defmodule ElixirQuest.Aspects.Location do
  @moduledoc """
  All entities which physically exist in the game world will have a Location component
  with the id of its region and the x/y coordinates where it are currently located.
  """
  use ECSx.Aspect,
    schema: {:entity_id, :region_id, :x, :y}

  alias ETS.Set, as: Ets
  alias Phoenix.PubSub

  def add_and_broadcast(entity_id, region_id, x, y) do
    add(entity_id: entity_id, region_id: region_id, x: x, y: y)

    PubSub.broadcast(EQPubSub, "region:#{region_id}", {:spawned, entity_id, {x, y}})
  end

  def get_all_from_region(region_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.match_object!({:_, region_id, :_, :_})
  end

  def remove_and_broadcast(entity_id) do
    %{region_id: region_id, x: x, y: y} = get(entity_id)

    remove(entity_id)

    PubSub.broadcast(EQPubSub, "region:#{region_id}", {:removed, entity_id, {x, y}})
  end

  @doc """
  Updates the location of an entity to a given coordinate.
  `region_id` is for broadcasting only and will not update the entity's region.
  """
  def update(entity_id, region_id, {x, y}, previous) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.update_element!(entity_id, [{3, x}, {4, y}])

    PubSub.broadcast(EQPubSub, "region:#{region_id}", {:moved, entity_id, {x, y}, previous})
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
