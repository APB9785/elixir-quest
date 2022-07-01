defmodule ElixirQuest.Manager do
  @moduledoc """
  The Manager spawns and owns all Component tables.  No other process may write to the
  tables - this ensures activity is serialized to prevent race conditions.

  Each tick, this server will run the appropriate Systems, writing the updates as it goes.

  Updates from the LiveView clients will use a standard GenServer API.
  """
  use ECSx.Manager, tick_rate: 20

  alias ElixirQuest.Aspects.Attacking
  alias ElixirQuest.Aspects.Location
  alias ElixirQuest.Aspects.Moving
  alias ElixirQuest.Aspects.PlayerChar
  alias ElixirQuest.Mobs
  alias ElixirQuest.PlayerChars
  alias ElixirQuest.PlayerChars.PlayerChar, as: PC
  alias ElixirQuest.Regions

  setup do
    Mobs.spawn_all()
    Regions.load_all_boundaries()
  end

  def handle_call({:spawn_pc, %PC{} = pc}, _from, state) do
    cond do
      PlayerChar.has_component?(pc.id) ->
        {:reply, :already_spawned, state}

      Location.occupied?(pc.region_id, pc.x_pos, pc.y_pos) ->
        {:reply, :blocked, state}

      :otherwise ->
        PlayerChars.spawn(pc)
        {:reply, :success, state}
    end
  end

  def handle_call({:despawn_pc, %PC{} = pc}, _from, state) do
    PlayerChars.despawn(pc)

    {:reply, :success, state}
  end

  def handle_cast({:add_moving, entity_id, direction}, state) do
    Moving.add_component(entity_id: entity_id, direction: direction)

    {:noreply, state}
  end

  def handle_cast({:remove_moving, entity_id}, state) do
    Moving.remove_component(entity_id)

    {:noreply, state}
  end

  def handle_cast({:begin_attack, entity_id, target_id}, state) do
    Attacking.add_component(entity_id: entity_id, target_id: target_id)

    {:noreply, state}
  end

  def handle_cast({:cancel_attack, entity_id}, state) do
    Attacking.remove_component(entity_id)

    {:noreply, state}
  end

  ## Aspect / System Modules

  def aspects do
    [
      ElixirQuest.Aspects.Aggro,
      ElixirQuest.Aspects.Attacking,
      ElixirQuest.Aspects.Cooldown,
      ElixirQuest.Aspects.Dead,
      ElixirQuest.Aspects.Equipment,
      ElixirQuest.Aspects.Experience,
      ElixirQuest.Aspects.Health,
      ElixirQuest.Aspects.Image,
      ElixirQuest.Aspects.Level,
      ElixirQuest.Aspects.Location,
      ElixirQuest.Aspects.MovementSpeed,
      ElixirQuest.Aspects.Moving,
      ElixirQuest.Aspects.Name,
      ElixirQuest.Aspects.PlayerChar,
      ElixirQuest.Aspects.Respawn,
      ElixirQuest.Aspects.Seeking,
      ElixirQuest.Aspects.Wandering
    ]
  end

  def systems do
    [
      ElixirQuest.Systems.Aggro,
      ElixirQuest.Systems.Attacks,
      ElixirQuest.Systems.BackupState,
      ElixirQuest.Systems.Death,
      ElixirQuest.Systems.Movement,
      ElixirQuest.Systems.PruneCooldowns,
      ElixirQuest.Systems.Respawn,
      ElixirQuest.Systems.Seek,
      ElixirQuest.Systems.Wander
    ]
  end

  ## LiveView Client API

  @doc """
  Spawns a Player Character.
  """
  def spawn_pc(%PC{} = pc) do
    GenServer.call(__MODULE__, {:spawn_pc, pc})
  end

  def despawn_pc(%PC{} = pc) do
    GenServer.call(__MODULE__, {:despawn_pc, pc})
  end

  def add_moving(entity_id, direction) do
    GenServer.cast(__MODULE__, {:add_moving, entity_id, direction})
  end

  def remove_moving(entity_id) do
    GenServer.cast(__MODULE__, {:remove_moving, entity_id})
  end

  def begin_attack(entity_id, target_id) do
    GenServer.cast(__MODULE__, {:begin_attack, entity_id, target_id})
  end

  def cancel_attack(entity_id) do
    GenServer.cast(__MODULE__, {:cancel_attack, entity_id})
  end
end
