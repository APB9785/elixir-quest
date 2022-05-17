defmodule ElixirQuest.Components.Attacking do
  @moduledoc """
  When an entity starts attacking, it will gain the Attacking component with a reference
  to its target.  If the target changes, then the component must be updated.
  """
  alias ETS.Set, as: Ets

  def initialize_table, do: Ets.new!(name: __MODULE__)

  def add(entity_id, target_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.put!({entity_id, target_id})
  end

  def remove(entity_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.delete!(entity_id)
  end

  def get_all do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.to_list!()
  end
end
