defmodule ElixirQuest.Components.Action do
  @moduledoc """
  Any actions which can be taken by an Entity will be represented by an Action component.
  Since most Entities will have several possible actions, we use a Bag table.
  Each action will have a timestamp to represent the "cooldown" time, and a boolean flag to
  show whether the Entity is actively taking the action.
  """
  alias ETS.Bag, as: Ets

  def initialize_table, do: Ets.new!(name: __MODULE__)

  def add(entity_id, action, timestamp, active?) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.add!({entity_id, action, timestamp, active?})
  end

  def get(entity_id, action) do
    table = Ets.wrap_existing!(__MODULE__)

    case Ets.match_object!(table, {entity_id, action, :_, :_}, 1) do
      {[], :end_of_table} -> nil
      {[result], _} -> result
    end
  end

  def get_all_active do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.match_object!({:_, :_, :_, true})
  end

  def activate(entity_id, action) do
    table = Ets.wrap_existing!(__MODULE__)

    {^entity_id, ^action, timestamp, _} = get(entity_id, action)

    Ets.match_delete!(table, {entity_id, action, :_, :_})
    Ets.add!(table, {entity_id, action, timestamp, true})
  end

  def deactivate(entity_id, action) do
    table = Ets.wrap_existing!(__MODULE__)

    {^entity_id, ^action, timestamp, _} = get(entity_id, action)

    Ets.match_delete!(table, {entity_id, action, :_, :_})
    Ets.add!(table, {entity_id, action, timestamp, false})
  end

  @doc """
  Resets a given cooldown after the action is taken, or when an action fails.
  """
  def reset_cooldown({entity_id, action, _time, active?}) do
    next_time = NaiveDateTime.utc_now()

    do_reset_cooldown(entity_id, action, next_time, active?)
  end

  def reset_cooldown({entity_id, action, _time, active?}, cooldown) do
    now = NaiveDateTime.utc_now()
    next_time = NaiveDateTime.add(now, cooldown, :millisecond)

    do_reset_cooldown(entity_id, action, next_time, active?)
  end

  defp do_reset_cooldown(entity_id, action, next_time, active?) do
    table = Ets.wrap_existing!(__MODULE__)

    Ets.match_delete!(table, {entity_id, action, :_, :_})
    Ets.add!(table, {entity_id, action, next_time, active?})
  end
end
