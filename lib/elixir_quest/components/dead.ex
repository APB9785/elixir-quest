defmodule ElixirQuest.Components.Dead do
  @moduledoc """
  Helpers for running ETS queries for the Dead components
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
