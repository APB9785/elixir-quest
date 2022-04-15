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

  alias ElixirQuest.Mobs
  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.PlayerChars.PlayerChar
  alias ElixirQuest.Regions
  alias ElixirQuest.Systems
  alias ETS.Set, as: Ets
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
      location: Ets.new!(name: :location),
      health: Ets.new!(name: :health),
      cooldown: Ets.new!(name: :cooldown),
      moving: Ets.new!(name: :moving),
      target: Ets.new!(name: :target),
      seeking: Ets.new!(name: :seeking),
      wandering: Ets.new!(name: :wandering),
      aggro: Ets.new!(name: :aggro),
      equipped: Ets.new!(name: :equipped),
      player_chars: Ets.new!(name: :player_chars),
      image: Ets.new!(name: :image),
      name: Ets.new!(name: :name),
      dead: Ets.new!(name: :dead)
    }

    {:ok, state, {:continue, :load}}
  end

  def handle_continue(:load, state) do
    mobs = Mobs.load_all()
    regions = Regions.load_all()

    Enum.each(mobs, fn %Mob{id: id} = mob ->
      add(:location, id, mob.region_id, {mob.x_pos, mob.y_pos})
      add(:health, id, mob.max_hp, mob.max_hp)
      add(:wandering, id)
      add(:aggro, id, mob.aggro_range)
      add(:image, id, "goblin.png")
      add(:name, id, mob.name)
    end)

    Enum.each(regions, &Regions.load_boundaries/1)

    {:noreply, state}
  end

  def handle_call({:spawn_pc, %PlayerChar{id: id} = pc}, _from, state) do
    cond do
      get(:player_chars, id) ->
        {:reply, :already_spawned, state}

      location_occupied?(pc.region_id, {pc.x_pos, pc.y_pos}) ->
        {:reply, :blocked, state}

      :otherwise ->
        add(:location, id, pc.region_id, {pc.x_pos, pc.y_pos})
        add(:health, id, pc.current_hp, pc.max_hp)
        add(:player_chars, id)
        add(:image, id, "knight.png")
        add(:name, id, pc.name)
        add(:equipped, id, %{weapon: %{name: "hands", damage: 1, cooldown: 1000}})

        {:reply, :success, state}
    end
  end

  def handle_cast({:move, entity_id, region_id, destination}, state) do
    unless location_occupied?(region_id, destination) do
      update_location(entity_id, destination)
    end

    {:noreply, state}
  end

  def handle_cast({:target, id, target_id}, state) do
    add(:target, id, target_id)

    {:noreply, state}
  end

  def handle_cast({:cooldown, id, action}, state) do
    case get(:cooldown, {id, action}) do
      nil ->
        add(:cooldown, id, action, NaiveDateTime.utc_now())

      _ ->
        :noop
    end

    {:noreply, state}
  end

  def handle_cast({:remove_target_from_all, target_id}, state) do
    :target
    |> Ets.wrap_existing!()
    |> Ets.match_delete({:_, target_id})

    {:noreply, state}
  end

  def handle_info({:tick, tick}, state) do
    # TODO: make this async

    Enum.each(@system_frequencies, fn {system, frequency} ->
      if rem(tick, frequency) == 0 do
        apply(Systems, system, [])
      end
    end)

    {:noreply, state}
  end

  ## Systems API

  @doc """
  Adds a component to an entity.
  """
  def add(:seeking, id), do: :seeking |> Ets.wrap_existing!() |> Ets.put!({id})
  def add(:wandering, id), do: :wandering |> Ets.wrap_existing!() |> Ets.put!({id})
  def add(:player_chars, id), do: :player_chars |> Ets.wrap_existing!() |> Ets.put!({id})
  def add(:dead, id), do: :dead |> Ets.wrap_existing!() |> Ets.put!({id})

  def add(:moving, id, {vx, vy}), do: :moving |> Ets.wrap_existing!() |> Ets.put!({id, {vx, vy}})
  def add(:image, id, filename), do: :image |> Ets.wrap_existing!() |> Ets.put!({id, filename})
  def add(:name, id, name), do: :name |> Ets.wrap_existing!() |> Ets.put!({id, name})

  def add(:target, id, target_id),
    do: :target |> Ets.wrap_existing!() |> Ets.put!({id, target_id})

  def add(:aggro, id, range), do: :aggro |> Ets.wrap_existing!() |> Ets.put!({id, range})

  def add(:equipped, id, equipment),
    do: :equipped |> Ets.wrap_existing!() |> Ets.put!({id, equipment})

  def add(:location, id, region, {x, y}),
    do: :location |> Ets.wrap_existing!() |> Ets.put!({id, region, {x, y}})

  def add(:health, id, hp, max_hp),
    do: :health |> Ets.wrap_existing!() |> Ets.put!({id, hp, max_hp})

  def add(:cooldown, id, action, time),
    do: :cooldown |> Ets.wrap_existing!() |> Ets.put!({{id, action}, time})

  @doc """
  Removes a component from an entity.
  """
  def remove(component, entity_id), do: component |> Ets.wrap_existing!() |> Ets.delete(entity_id)

  @doc """
  Get all components of a specified type.
  """
  def get_all(component_type), do: component_type |> Ets.wrap_existing!() |> Ets.to_list!()

  @doc """
  Gets a component from the given table by entity ID.
  """
  def get(table, id) do
    result =
      table
      |> Ets.wrap_existing!()
      |> Ets.get!(id)

    if is_nil(result) do
      nil
    else
      case Tuple.delete_at(result, 0) do
        {single} -> single
        multiple -> multiple
      end
    end
  end

  def search_location(region_id, coord) do
    table = Ets.wrap_existing!(:location)

    case Ets.match!(table, {:"$1", region_id, coord}, 1) do
      {[], :end_of_table} -> nil
      {[[entity_id]], _} -> entity_id
    end
  end

  @doc """
  Check a location to see if it is already occupied.
  """
  def location_occupied?(region_id, coord) do
    case search_location(region_id, coord) do
      nil -> false
      _ -> true
    end
  end

  @doc """
  Updates the location of an entity to a given coordinate.  Region is unchanged.
  """
  def update_location(entity_id, {_x, _y} = destination) do
    :location
    |> Ets.wrap_existing!()
    |> Ets.update_element!(entity_id, {3, destination})
  end

  @doc """
  Updates the location of an entity to a given region and coordinate.
  """
  def update_location(entity_id, region_id, {_x, _y} = destination) do
    :location
    |> Ets.wrap_existing!()
    |> Ets.update_element!(entity_id, [{2, region_id}, {3, destination}])
  end

  @doc """
  Decrements the given entity's current hp.
  """
  def decrease_current_hp(entity_id, amount) do
    {current_hp, _max_hp} = get(:health, entity_id)
    health_table = Ets.wrap_existing!(:health)

    case current_hp - amount do
      new_hp when new_hp <= 0 ->
        add(:dead, entity_id)
        Ets.update_element!(health_table, entity_id, {2, 0})

      new_hp ->
        Ets.update_element!(health_table, entity_id, {2, new_hp})
    end
  end

  @doc """
  Resets a given cooldown after the action is taken, or when an action fails.
  """
  def reset_cooldown({{entity_id, action}, _time}) do
    next_time = NaiveDateTime.utc_now()
    do_reset_cooldown(entity_id, action, next_time)
  end

  def reset_cooldown({{entity_id, action}, time}, cooldown) do
    next_time = NaiveDateTime.add(time, cooldown, :millisecond)
    do_reset_cooldown(entity_id, action, next_time)
  end

  defp do_reset_cooldown(entity_id, action, next_time) do
    :cooldown
    |> Ets.wrap_existing!()
    |> Ets.update_element!({entity_id, action}, {2, next_time})
  end

  ## Client API

  @doc """
  Spawns a Player Character.
  """
  def spawn_pc(%PlayerChar{} = pc) do
    GenServer.call(__MODULE__, {:spawn_pc, pc})
  end

  def attempt_move(entity_id, region_id, {_x, _y} = destination) do
    GenServer.cast(__MODULE__, {:move, entity_id, region_id, destination})
  end

  def add_target(id, target_id) do
    GenServer.cast(__MODULE__, {:target, id, target_id})
  end

  def add_cooldown(id, action) do
    GenServer.cast(__MODULE__, {:cooldown, id, action})
  end

  def remove_target_from_all(entity_id) do
    GenServer.cast(__MODULE__, {:remove_target_from_all, entity_id})
  end
end
