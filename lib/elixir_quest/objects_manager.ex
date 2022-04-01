defmodule ElixirQuest.ObjectsManager do
  @moduledoc """
  This is the process which owns the objects table.  It is the only process which
  is allowed to write to the table.  No validation will happen in this process, so
  any incoming messages must already have been checked for race conditions or other
  invalid updates.
  """
  use GenServer

  alias ElixirQuest.Mobs
  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.Objects
  alias ElixirQuest.Regions
  alias ElixirQuest.Utils
  alias ETS.Set, as: Ets

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: {:via, Registry, {:eq_reg, __MODULE__}})
  end

  def init(_) do
    Logger.info("Objects Manager initialized")
    {:ok, [], {:continue, :receive_ets_transfer}}
  end

  def handle_continue(:receive_ets_transfer, _) do
    {:ok, %{set: objects}} = Ets.accept()
    Logger.info("Objects table giveaway successful")

    {:noreply, objects, {:continue, :load_objects}}
  end

  def handle_continue(:load_objects, objects) do
    mobs = Mobs.load_all()
    regions = Regions.load_all()

    Enum.each(mobs, fn mob ->
      to_insert = Mob.to_ets(mob)
      Ets.put!(objects, to_insert)
    end)

    Enum.each(regions, fn region ->
      Objects.load_boundaries(objects, region)
    end)

    {:noreply, objects}
  end

  # Updates the objects table with a move if the destination is not occupied
  def handle_cast({:move, object, destination}, objects) do
    case Objects.get_by_location(destination, object.region_id) do
      :empty -> Objects.update_position(objects, object, destination)
      _ -> nil
    end

    {:noreply, objects}
  end

  def handle_cast({:assign_target, object_id, target_id}, objects) do
    Objects.assign_target(objects, object_id, target_id)

    {:noreply, objects}
  end

  # This will handle all new spawns
  # TODO: What if the object attempts to spawn at a coordinate which is already occupied?
  def handle_call({:spawn, object}, _from, objects) do
    case Objects.get_by_location({object.x_pos, object.y_pos}, object.region_id) do
      :empty ->
        Objects.spawn(objects, object)
        {:reply, {:ok, object}, objects}

      result ->
        Logger.error("#{object.name} failed to spawn (collision with #{elem(result, 2)})")
        {:reply, {:error, :collision}, objects}
    end
  end

  ## API

  @doc """
  Attempt to move an object to the given coordinate.  This will fail silently if the
  coordinate is already occupied.
  """
  @spec attempt_move(Mob.t() | PlayerChar.t(), {integer(), integer()}) :: :ok
  def attempt_move(object, destination) do
    objects_manager = {:via, Registry, {:eq_reg, __MODULE__}}
    GenServer.cast(objects_manager, {:move, object, destination})
  end

  @doc """
  Attempt to spawn an object to the given coordinate.  Returns `{:ok, object}` if successful
  and `{:error, :collision}` otherwise.
  """
  @spec attempt_spawn(Mob.t() | PlayerChar.t()) :: :ok
  def attempt_spawn(object) do
    objects_manager = {:via, Registry, {:eq_reg, __MODULE__}}
    GenServer.call(objects_manager, {:spawn, object})
  end

  @doc """
  Attempt a target by ID to a given object.
  """
  @spec assign_target(Mob.t() | PlayerChar.t(), Ecto.UUID.t()) :: :ok
  def assign_target(object, target_id) do
    objects_manager = {:via, Registry, {:eq_reg, __MODULE__}}
    GenServer.cast(objects_manager, {:assign_target, object.id, target_id})
  end

  @doc """
  Gives ownership of a table to the Objects Manager
  """
  def give_table(objects) do
    objects_manager = Utils.lookup_pid(__MODULE__)
    Ets.give_away!(objects, objects_manager)
  end
end
