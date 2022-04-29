defmodule ElixirQuest.Components.Target do
  @moduledoc """
  Helpers for running ETS queries for the Target components
  """
  alias ETS.Set, as: Ets

  def initialize_table, do: Ets.new!(name: __MODULE__)

  def add(entity_id, target_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.put!({entity_id, target_id})
  end

  def get(entity_id) do
    table = Ets.wrap_existing!(__MODULE__)

    case Ets.get!(table, entity_id) do
      nil -> nil
      {^entity_id, target_id} -> target_id
    end
  end

  def remove_from_all(target_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.match_delete!({:_, target_id})
  end
end
