defmodule ElixirQuest.Components.Health do
  @moduledoc """
  All living entities have a Health component which tracks their current hp and maximum hp.
  """
  alias ETS.Set, as: Ets

  def initialize_table, do: Ets.new!(name: __MODULE__)

  def add(entity_id, current_hp, max_hp) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.put!({entity_id, current_hp, max_hp})
  end

  def get(entity_id) do
    table = Ets.wrap_existing!(__MODULE__)

    case Ets.get!(table, entity_id) do
      nil -> nil
      {^entity_id, current_hp, max_hp} -> {current_hp, max_hp}
    end
  end

  def remove(entity_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.delete!(entity_id)
  end

  @doc """
  Decrements the given entity's current hp.
  """
  def decrease_current_hp(entity_id, amount) do
    {current_hp, _max_hp} = get(entity_id)
    table = Ets.wrap_existing!(__MODULE__)

    new_hp = current_hp - amount

    Ets.update_element!(table, entity_id, {2, new_hp})
    Phoenix.PubSub.broadcast(EQPubSub, "entity:#{entity_id}", {:hp_change, entity_id, new_hp})

    new_hp
  end
end
