defmodule ElixirQuest.Components.Dead do
  @moduledoc """
  When an entity is going to die (usually from dropping to zero hp or below), the Dead
  component is added.  This allows all Systems for this tick to finish executing before
  the entity is killed.
  """
  alias ETS.Set, as: Ets

  def initialize_table, do: Ets.new!(name: __MODULE__)

  def add(entity_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.put!({entity_id})
  end

  def get_all do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.to_list!()
    |> Enum.map(fn {id} -> id end)
  end

  def has_component?(entity_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.has_key!(entity_id)
  end

  def remove(entity_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.delete!(entity_id)
  end
end
