defmodule ElixirQuest.Components.Seeking do
  @moduledoc """
  When a mob is aggro'ed to a PC, it will gain a Seeking component, which marks that it
  should cease its default behavior and instead move towards its target and attack.
  """
  alias ETS.Set, as: Ets

  def initialize_table, do: Ets.new!(name: __MODULE__)

  def add(entity_id, target_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.put!({entity_id, target_id})
  end

  def get_all do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.to_list!()
  end

  def remove(entity_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.delete!(entity_id)
  end

  def has_target?(entity_id) do
    table = Ets.wrap_existing!(__MODULE__)

    case Ets.get!(table, entity_id) do
      nil -> false
      _ -> true
    end
  end
end
