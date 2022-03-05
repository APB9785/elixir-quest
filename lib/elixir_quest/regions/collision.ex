defmodule ElixirQuest.Collision do
  @moduledoc """
  This is the system which validates movements to prevent collision or movement out of bounds.
  """
  use GenServer

  # alias ElixirQuest.Mobs
  # alias ElixirQuest.Regions
  alias ElixirQuest.Regions.Region
  alias ElixirQuest.Utils
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
    objects_manager = Utils.lookup_pid(:objects_manager)

    # Request new collison table
    TableManager.spawn_location_index()

    # Receive new collision table
    {:ok, location_index, _, _} = Ets.accept()
    Logger.info("Location index giveaway successful")

    %Region{raw_map: raw_map, mobs: mobs} = Region.load_with_mobs(name)

    Enum.each(mobs, &spawn_object(&1, location_index, objects_manager))
    load_boundaries(raw_map, location_index)

    state = %{
      location_index: location_index,
      objects_manager: objects_manager
    }

    {:noreply, state}
  end

  def handle_cast({:move, object_id, current_location, destination}, state) do
    %{objects_manager: objects_manager, location_index: location_index} = state

    case Ets.get!(location_index, destination) do
      nil ->
        # OK to move there - update location_index table
        Ets.delete(location_index, current_location)
        Ets.put!(location_index, destination, object_id)
        # Update the main region table
        GenServer.cast(objects_manager, {:move, object_id, destination})

      _ ->
        # Blocked!
        :ok
    end

    {:noreply, state}
  end

  def handle_cast({:spawn, object}, state) do
    spawn_object(object, state.location_index, state.objects_manager)

    {:noreply, state}
  end

  # Adds the location to the index table, then messages the region manager to insert the
  # object into the main ETS table.
  #
  # TODO: What if the object attempts to spawn at a coordinate which is already occupied?
  #
  defp spawn_object(object, location_index, objects_manager) do
    case Ets.put(location_index, {object.x_pos, object.y_pos}, object.id) do
      {:ok, _} ->
        GenServer.cast(objects_manager, {:spawn, object})

      {:error, error} ->
        Logger.error("#{object.region}: Object #{object.name} failed to spawn (#{error})")
    end
  end

  # This will read the raw_map of a region and add the boundaries to its location_index.
  # The value will be set to `:rock`.
  defp load_boundaries(raw_map, location_index) do
    raw_map
    |> String.graphemes()
    |> parse_txt(location_index)
  end

  defp parse_txt(map, location_index, x \\ 0, y \\ 0)
  defp parse_txt([], _, _, _), do: :ok
  defp parse_txt(["\n" | rest], index, _x, y), do: parse_txt(rest, index, 0, y + 1)
  defp parse_txt([" " | rest], index, x, y), do: parse_txt(rest, index, x + 1, y)

  defp parse_txt(["#" | rest], index, x, y) do
    Ets.put!(index, {x, y}, :rock)
    parse_txt(rest, index, x + 1, y)
  end

  # Public functions

  def get_pid(name) do
    Utils.lookup_pid({:collision, name})
  end

  def move(collision_server, object_id, current_location, destination) do
    GenServer.cast(collision_server, {:move, object_id, current_location, destination})
  end
end
