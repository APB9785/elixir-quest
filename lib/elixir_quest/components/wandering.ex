defmodule ElixirQuest.Components.Wandering do
  @moduledoc """
  This component is added to any mobs which are not currently aggro'ed to a target.
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

  def remove(entity_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.delete!(entity_id)
  end
end
