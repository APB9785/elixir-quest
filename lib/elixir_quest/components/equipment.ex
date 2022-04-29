defmodule ElixirQuest.Components.Equipment do
  @moduledoc """
  Helpers for running ETS queries for the Equipment components
  """
  alias ETS.KeyValueSet, as: Ets

  def initialize_table, do: Ets.new!(name: __MODULE__)

  def add(entity_id, equipment_map) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.put!(entity_id, equipment_map)
  end

  def get(entity_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.get!(entity_id)
  end
end
