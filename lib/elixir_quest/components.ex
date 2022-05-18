defmodule ElixirQuest.Components do
  @moduledoc """
  The Components server spanws and owns all Component tables.  No other process may write to the
  tables - this ensures activity is serialized to prevent race conditions.

  Each tick, this server will run the appropriate Systems, writing the updates as it goes.

  Updates from the LiveView clients will use a standard GenServer API.
  """
  use GenServer

  alias ElixirQuest.Components.Aggro
  alias ElixirQuest.Components.Attacking
  alias ElixirQuest.Components.Cooldown
  alias ElixirQuest.Components.Dead
  alias ElixirQuest.Components.Equipment
  alias ElixirQuest.Components.Experience
  alias ElixirQuest.Components.Health
  alias ElixirQuest.Components.Image
  alias ElixirQuest.Components.Level
  alias ElixirQuest.Components.Location
  alias ElixirQuest.Components.Moving
  alias ElixirQuest.Components.MovementSpeed
  alias ElixirQuest.Components.Name
  alias ElixirQuest.Components.PlayerChar
  alias ElixirQuest.Components.Respawn
  alias ElixirQuest.Components.Seeking
  alias ElixirQuest.Components.Wandering
  alias ElixirQuest.Mobs
  alias ElixirQuest.PlayerChars.PlayerChar, as: PC
  alias ElixirQuest.Regions
  alias ElixirQuest.Systems
  alias Phoenix.PubSub

  require Logger

  @system_frequencies Systems.frequencies()

  @pc_image_filename "knight.png"
  @pc_base_movement_speed 250
  @weapon_hands_stats %{name: "hands", damage: 1, cooldown: 1000}

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Logger.info("Components initialized")
    PubSub.subscribe(EQPubSub, "tick")

    component_modules = [
      Aggro,
      Attacking,
      Cooldown,
      Dead,
      Equipment,
      Experience,
      Health,
      Image,
      Level,
      Location,
      MovementSpeed,
      Moving,
      Name,
      PlayerChar,
      Respawn,
      Seeking,
      Wandering
    ]

    Enum.each(component_modules, &apply(&1, :initialize_table, []))

    {:ok, [], {:continue, :load}}
  end

  def handle_continue(:load, state) do
    mobs = Mobs.load_all()
    regions = Regions.load_all()

    Enum.each(mobs, &Mobs.spawn/1)

    Enum.each(regions, &Regions.load_boundaries/1)

    {:noreply, state}
  end

  def handle_call({:spawn_pc, %PC{id: id} = pc}, _from, state) do
    cond do
      PlayerChar.has_component?(id) ->
        {:reply, :already_spawned, state}

      Location.occupied?(pc.region_id, pc.x_pos, pc.y_pos) ->
        {:reply, :blocked, state}

      :otherwise ->
        Location.add(id, pc.region_id, pc.x_pos, pc.y_pos)
        Health.add(id, pc.current_hp, pc.max_hp)
        PlayerChar.add(id)
        Level.add(id, pc.level)
        Experience.add(id, pc.experience)
        Image.add(id, @pc_image_filename)
        Name.add(id, pc.name)
        Equipment.add(id, %{weapon: @weapon_hands_stats})
        MovementSpeed.add(id, @pc_base_movement_speed)

        {:reply, :success, state}
    end
  end

  def handle_cast({:add_moving, entity_id, direction}, state) do
    Moving.add(entity_id, direction)

    {:noreply, state}
  end

  def handle_cast({:remove_moving, entity_id}, state) do
    Moving.remove(entity_id)

    {:noreply, state}
  end

  def handle_cast({:begin_attack, entity_id, target_id}, state) do
    Attacking.add(entity_id, target_id)

    {:noreply, state}
  end

  def handle_cast({:cancel_attack, entity_id}, state) do
    Attacking.remove(entity_id)

    {:noreply, state}
  end

  def handle_info({:tick, tick}, state) do
    # TODO: make this async?

    Enum.each(@system_frequencies, fn {system, frequency} ->
      if rem(tick, frequency) == 0 do
        apply(Systems, system, [])
      end
    end)

    {:noreply, state}
  end

  ## LiveView Client API

  @doc """
  Spawns a Player Character.
  """
  def spawn_pc(%PC{} = pc) do
    GenServer.call(__MODULE__, {:spawn_pc, pc})
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
