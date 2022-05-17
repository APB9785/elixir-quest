defmodule ElixirQuest.Components.Moving do
  @moduledoc """
  Entities currently moving have a Moving component, which holds the direction of movement.
  """
  alias ETS.Set, as: Ets

  def initialize_table, do: Ets.new!(name: __MODULE__)

  def add(entity_id, direction) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.put!({entity_id, direction})
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