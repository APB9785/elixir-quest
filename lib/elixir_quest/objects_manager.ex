defmodule ElixirQuest.ObjectsManager do
  @moduledoc """
  This is the process which owns the objects table.  It is the only process which
  is allowed to write to the table.  No validation will happen in this process, so
  any incoming messages must already have been checked for race conditions or other
  invalid updates.
  """
  use GenServer

  alias ETS.KeyValueSet, as: Ets

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: {:via, Registry, {:eq_reg, :objects_manager}})
  end

  def init(_) do
    Logger.info("Objects Manager initialized")
    {:ok, [], {:continue, :receive_ets_transfer}}
  end

  def handle_continue(:receive_ets_transfer, _) do
    {:ok, objects, _, _} = Ets.accept()
    Logger.info("Objects table giveaway successful")

    {:noreply, objects}
  end

  # Updates the objects table with a move (validated beforehand by region's collision server)
  def handle_cast({:move, object_id, destination}, objects) do
    Objects.update_position(objects, object_id, destination)
    {:noreply, objects}
  end

  # This will handle all new spawns (validated beforehand by region's collision server)
  def handle_cast({:spawn, object}, objects) do
    case Objects.spawn(objects, object) do
      {:ok, _} -> :ok
      {:error, _} -> Logger.error("#{object.region}: #{object.name} failed to spawn")
    end

    {:noreply, objects}
  end

  @doc """
  Gives ownership of a table to the Objects Manager
  """
  def give_table(objects) do
    [{objects_manager, _}] = Registry.lookup(:eq_reg, :objects_manager)
    Ets.give_away!(objects, objects_manager)
  end
end
