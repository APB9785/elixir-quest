defmodule ElixirQuest.TableManager do
  @moduledoc """
  This is the process which creates all the ETS tables.  It is the only
  process which is allowed to write to the table.  No validation will happen in
  this process, so any incoming messages must already have been checked for race
  conditions or other invalid updates.
  """
  use GenServer

  alias ElixirQuest.ObjectsManager
  # alias ElixirQuest.Regions.Region
  alias ElixirQuest.Utils
  alias ETS.KeyValueSet, as: Ets

  require ETS.KeyValueSet
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: {:via, Registry, {:eq_reg, :table_manager}})
  end

  def init(_) do
    objects =
      Ets.new!(
        name: :objects,
        read_concurrency: true,
        heir: {self(), {:owner_crashed, :objects_manager}}
      )

    Logger.info("Objects table spawned by Table Manager")

    ObjectsManager.give_table(objects)
    Logger.info("Objects table giveaway initiated")

    {:ok, []}
  end

  def handle_cast({:spawn_location_index, collision_server}, state) do
    location_index =
      Ets.new!(
        name: :location_index,
        read_concurrency: true,
        heir: {self(), :owner_crashed}
      )

    Logger.info("Location index spawned by Table Manager")

    Ets.give_away!(location_index, collision_server)
    Logger.info("Location index giveaway initiated")

    {:noreply, state}
  end

  # Send region info to players when they join
  def handle_call(:join, _from, region) do
    {:reply, region, region}
  end

  Ets.accept {:owner_crashed, registry_key}, table, _from, state do
    new_owner = lookup_until_alive(registry_key)
    Ets.give_away!(table, new_owner)

    {:noreply, state}
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
  Spawns a new location index and gives it away to the caller.

  Returns :ok
  """
  def spawn_location_index do
    table_manager = Utils.lookup_pid(:table_manager)
    GenServer.cast(table_manager, {:spawn_location_index, self()})
  end
end
