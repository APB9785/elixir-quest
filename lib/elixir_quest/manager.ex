defmodule ElixirQuest.Manager do
  @moduledoc """
  The Manager spawns and owns all Component tables.  No other process may write to the
  tables - this ensures activity is serialized to prevent race conditions.

  Each tick, this server will run the appropriate Systems, writing the updates as it goes.

  Updates from the LiveView clients will use a standard GenServer API.
  """
  use GenServer

  alias ElixirQuest.Aspects.Aggro
  alias ElixirQuest.Aspects.Attacking
  alias ElixirQuest.Aspects.Cooldown
  alias ElixirQuest.Aspects.Dead
  alias ElixirQuest.Aspects.Equipment
  alias ElixirQuest.Aspects.Experience
  alias ElixirQuest.Aspects.Health
  alias ElixirQuest.Aspects.Image
  alias ElixirQuest.Aspects.Level
  alias ElixirQuest.Aspects.Location
  alias ElixirQuest.Aspects.Moving
  alias ElixirQuest.Aspects.MovementSpeed
  alias ElixirQuest.Aspects.Name
  alias ElixirQuest.Aspects.PlayerChar
  alias ElixirQuest.Aspects.Respawn
  alias ElixirQuest.Aspects.Seeking
  alias ElixirQuest.Aspects.Wandering
  alias ElixirQuest.Logs
  alias ElixirQuest.Mobs
  alias ElixirQuest.PlayerChars.PlayerChar, as: PC
  alias ElixirQuest.Regions
  alias Phoenix.PubSub

  @pc_image_filename "knight.png"
  @pc_base_movement_speed 250
  @weapon_hands_stats %{name: "hands", damage: 1, cooldown: 1000, range: 1.9}

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    PubSub.subscribe(EQPubSub, "tick")

    Enum.each(aspects(), fn module -> module.init() end)

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
        Location.add_and_broadcast(id, pc.region_id, pc.x_pos, pc.y_pos)
        Health.add_component(entity_id: id, current_hp: pc.current_hp, max_hp: pc.max_hp)
        PlayerChar.add_component(entity_id: id)
        Level.add_component(entity_id: id, level: pc.level)
        Experience.add_component(entity_id: id, experience: pc.experience)
        Image.add_component(entity_id: id, image_filename: @pc_image_filename)
        Name.add_component(entity_id: id, name: pc.name)
        Equipment.add_component(entity_id: id, equipment_map: %{weapon: @weapon_hands_stats})
        MovementSpeed.add_component(entity_id: id, movement_speed: @pc_base_movement_speed)

        log_entry = Logs.from_spawn(pc.name)
        PubSub.broadcast(EQPubSub, "region:#{pc.region_id}", {:log_entry, log_entry})

        {:reply, :success, state}
    end
  end

  def handle_call({:despawn_pc, %PC{id: id}}, _from, state) do
    Location.remove_and_broadcast(id)

    Health.remove_component(id)
    PlayerChar.remove_component(id)
    Level.remove_component(id)
    Experience.remove_component(id)
    Image.remove_component(id)
    Name.remove_component(id)
    Equipment.remove_component(id)
    MovementSpeed.remove_component(id)

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

  def handle_info({:tick, tick}, state) do
    # TODO: make this async?

    Enum.each(systems(), fn system ->
      if rem(tick, system.__period__()) == 0 do
        system.run()
      end
    end)

    {:noreply, state}
  end

  ## Component / System Modules

  def aspects do
    [
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
