defmodule ElixirQuest.Components.Name do
  @moduledoc """
  All entities which can be targeted should have a Name component with the name to be displayed.

  Images currently don't change so this table's traffic is almost 100% reads.
  """
  alias ETS.Set, as: Ets

  def initialize_table, do: Ets.new!(name: __MODULE__, read_concurrency: true)

  def add(entity_id, name) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.put!({entity_id, name})
  end

  def get(entity_id) do
    table = Ets.wrap_existing!(__MODULE__)

    case Ets.get!(table, entity_id) do
      nil -> nil
      {^entity_id, name} -> name
    end
  end

  def remove(entity_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.delete!(entity_id)
  end
end
