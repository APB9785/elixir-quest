defmodule ElixirQuest.Components.Aggro do
  @moduledoc """
  Helpers for running ETS queries for the Aggro components
  """
  alias ETS.Set, as: Ets

  def initialize_table, do: Ets.new!(name: __MODULE__)

  def add(entity_id, aggro_range) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.put!({entity_id, aggro_range})
  end

  def get_all_with_ids do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.to_list!()
  end

  def remove(entity_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.delete!(entity_id)
  end
end
