defmodule ElixirQuest.Collision do
  @moduledoc """
  This is the system which validates movements to prevent collision or movement out of bounds.
  """
  use GenServer

  alias ElixirQuest.Mobs
  alias ElixirQuest.Regions
  alias ElixirQuest.Regions.Region
  alias ETS.KeyValueSet, as: Ets

  require Logger

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  defp via_tuple(name), do: {:via, Registry, {:eq_reg, {:collision, name}}}

  def init(name) do
    Logger.info("Region #{name}: Collision server initialized")
    {:ok, name, {:continue, :receive_ets_transfer}}
  end

  def handle_continue(:receive_ets_transfer, name) do
    {:ok, location_index, manager_pid, region} = Ets.accept()
    Logger.info("Region #{name}: ETS giveaway successful")

    mobs = Mobs.load_from_region(name)
    Enum.each(mobs, &spawn_object(&1, region))
    Regions.load_boundaries(region)

    {:noreply, region}
  end

  def handle_cast({:move, object_id, current_location, destination}, region) do
    %Region{manager: manager, location_index: location_index} = region

    case Ets.get!(location_index, destination) do
      nil ->
        # OK to move there - update location_index table
        Ets.delete(location_index, current_location)
        Ets.put!(location_index, destination, object_id)
        # Update the main region table
        GenServer.cast(manager, {:move, object_id, destination})

      _ ->
        # Blocked!
        :ok
    end

    {:noreply, region}
  end

  def handle_cast({:spawn, object}, region) do
    spawn_object(object, region)
    {:noreply, region}
  end

  @doc """
  Adds the location to the index table, then messages the region manager to insert the
  object into the main ETS table.

  TODO: What if the object attempts to spawn at a coordinate which is already occupied?

  """
  defp spawn_object(object, %Region{location_index: location_index, manager: manager}) do
    case Ets.put(location_index, {object.x_pos, object.y_pos}, object.id) do
      {:ok, _} ->
        GenServer.cast(manager, {:spawn, object})

      {:error, error} ->
        Logger.error("#{object.region}: Object #{object.name} failed to spawn (#{error})")
    end
  end
end
