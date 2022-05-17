defmodule ElixirQuest.Components.Cooldown do
  @moduledoc """
  Whenever an entity takes an action, it gains a Cooldown component, which stores the
  timestamp of when the cooldown expires and the action may be taken again.
  """
  alias ETS.Bag, as: Ets

  def initialize_table, do: Ets.new!(name: __MODULE__)

  def add(entity_id, action, timestamp) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.add!({entity_id, action, timestamp})
  end

  def remove(entity_id, action) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.match_delete!({entity_id, action, :_})
  end

  def ready?(entity_id, action) do
    table = Ets.wrap_existing!(__MODULE__)

    case Ets.match_object!(table, {entity_id, action, :_}, 1) do
      {[], :end_of_table} -> true
      {[_], _} -> false
    end
  end

  def get_all do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.to_list!()
  end
end
