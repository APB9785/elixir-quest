defmodule ElixirQuest.RegionManager do
  @moduledoc """
  This is the process which creates the ETS table for a region.  It is the only
  process which is allowed to write to the table.  No validation will happen in
  this process, so any incoming messages must already have been checked for race
  conditions or other invalid updates.
  """
  use GenServer

  import ETS.Acceptor

  # alias ElixirQuest.PlayerChars.PlayerChar
  # alias ElixirQuest.Regions
  alias ElixirQuest.Regions.Region
  alias ETS.KeyValueSet, as: Ets

  require Logger

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  defp via_tuple(name), do: {:via, Registry, {:eq_reg, {:manager, name}}}

  def init(name) do
    objects = Ets.new!(read_concurrency: true)
    location_index = Ets.new!(read_concurrency: true, heir: {self(), :owner_crashed})

    Logger.info("Region #{name}: ETS Initialized")

    {:ok, %{name: name, objects: objects, location_index: location_index},
     {:continue, :load_tables}}
  end

  def handle_continue(:load_tables, %{
        name: name,
        objects: objects,
        location_index: location_index
      }) do
    collision_server = lookup_until_alive({:collision, name})

    region =
      name
      |> Region.load()
      |> Map.put(:objects, objects)
      |> Map.put(:location_index, location_index)
      |> Map.put(:manager, self())
      |> Map.put(:collision_server, collision_server)

    Logger.info("Region #{name}: ETS finished loading")

    # The collision server will handle updates to the location index
    # Here we also send the region info to the collision server
    Ets.give_away!(location_index, collision_server, region)

    {:noreply, region}
  end

  # Send region info to players when they join
  def handle_call(:join, _from, region) do
    {:reply, region, region}
  end

  # Updates the objects table with a move (always validated beforehand by collision server)
  def handle_cast({:move, object_id, {x, y} = _destination}, %Region{objects: objects} = region) do
    object = Ets.get!(objects, object_id)
    updated_object = %{object | x_pos: x, y_pos: y}

    Ets.put!(objects, object_id, updated_object)

    {:noreply, region}
  end

  # This will handle all new spawns (always validated beforehand by collision server)
  def handle_cast({:spawn, object}, %Region{objects: objects} = region) do
    case Ets.put(objects, object.id, object) do
      {:ok, _} ->
        :ok

      {:error, _} ->
        Logger.error("#{object.region}: Object #{object.name} spawned but failed to index")
    end

    {:noreply, region}
  end

  accept Ets, table, _from, :owner_crashed, region do
    new_collision_server = lookup_until_alive({:collision, region.name})
    Ets.give_away!(table, new_collision_server, region)
  end

  defp lookup_until_alive(name_tuple) do
    [{collision_server, _}] = Registry.lookup(:eq_reg, name_tuple)

    if Process.alive?(collision_server) do
      collision_server
    else
      lookup_until_alive(name_tuple)
    end
  end

  # Public functions

  @doc """
  Returns region struct for a given region name.
  """
  def join(name) do
    [{manager_pid, _}] = Registry.lookup(:eq_reg, {:manager, name})
    GenServer.call(manager_pid, :join)
  end
end
