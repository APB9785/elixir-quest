defmodule ElixirQuest.Components do
  @moduledoc """
  This server holds a map of lists representing "Components" in the ECS pattern.
  Systems will access a component list in order to have an index of all objects which
  contain the desired component.

  For example, if the component is "Poison", then the list will hold the ids of each
  object which is currently poisoned. Each tick, the poison system will apply damage
  to all of the objects whose ids are on the list.
  """
  use GenServer

  alias ElixirQuest.Components.Action
  alias ElixirQuest.Components.Aggro
  alias ElixirQuest.Components.Dead
  alias ElixirQuest.Components.Equipment
  alias ElixirQuest.Components.Experience
  alias ElixirQuest.Components.Health
  alias ElixirQuest.Components.Image
  alias ElixirQuest.Components.Level
  alias ElixirQuest.Components.Location
  alias ElixirQuest.Components.Moving
  alias ElixirQuest.Components.Name
  alias ElixirQuest.Components.PlayerChar
  alias ElixirQuest.Components.Respawn
  alias ElixirQuest.Components.Seeking
  alias ElixirQuest.Components.Target
  alias ElixirQuest.Components.Wandering
  alias ElixirQuest.Mobs
  alias ElixirQuest.PlayerChars.PlayerChar, as: PC
  alias ElixirQuest.Regions
  alias ElixirQuest.Systems
  alias Phoenix.PubSub

  require Logger

  @system_frequencies Systems.frequencies()

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Logger.info("Components initialized")
    PubSub.subscribe(EQPubSub, "tick")

    state = %{
      action: Action.initialize_table(),
      aggro: Aggro.initialize_table(),
      dead: Dead.initialize_table(),
      equipment: Equipment.initialize_table(),
      experience: Experience.initialize_table(),
      health: Health.initialize_table(),
      image: Image.initialize_table(),
      level: Level.initialize_table(),
      location: Location.initialize_table(),
      moving: Moving.initialize_table(),
      name: Name.initialize_table(),
      player_char: PlayerChar.initialize_table(),
      respawn: Respawn.initialize_table(),
      seeking: Seeking.initialize_table(),
      target: Target.initialize_table(),
      wandering: Wandering.initialize_table()
    }

    {:ok, state, {:continue, :load}}
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
        Image.add(id, "knight.png")
        Name.add(id, pc.name)
        Equipment.add(id, %{weapon: %{name: "hands", damage: 1, cooldown: 1000}})
        Action.add(id, :attack, NaiveDateTime.utc_now(), false)

        {:reply, :success, state}
    end
  end

  def handle_cast({:move, entity_id, region_id, x, y}, state) do
    unless Location.occupied?(region_id, x, y) do
      Location.update(entity_id, x, y)
    end

    {:noreply, state}
  end

  def handle_cast({:target, entity_id, target_id}, state) do
    Target.add(entity_id, target_id)

    {:noreply, state}
  end

  def handle_cast({:remove_target_from_all, target_id}, state) do
    Target.remove_from_all(target_id)

    {:noreply, state}
  end

  def handle_cast({:begin_action, entity_id, action}, state) do
    Action.activate(entity_id, action)

    {:noreply, state}
  end

  def handle_cast({:cancel_action, entity_id, action}, state) do
    Action.deactivate(entity_id, action)

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

  ## Client API

  @doc """
  Spawns a Player Character.
  """
  def spawn_pc(%PC{} = pc) do
    GenServer.call(__MODULE__, {:spawn_pc, pc})
  end

  def attempt_move(entity_id, region_id, x, y) do
    GenServer.cast(__MODULE__, {:move, entity_id, region_id, x, y})
  end

  def add_target(entity_id, target_id) do
    GenServer.cast(__MODULE__, {:target, entity_id, target_id})
  end

  def remove_target_from_all(entity_id) do
    GenServer.cast(__MODULE__, {:remove_target_from_all, entity_id})
  end

  def begin_action(entity_id, action, previous) do
    if previous, do: cancel_action(entity_id, previous)
    GenServer.cast(__MODULE__, {:begin_action, entity_id, action})
  end

  def cancel_action(entity_id, action) do
    GenServer.cast(__MODULE__, {:cancel_action, entity_id, action})
  end
end
