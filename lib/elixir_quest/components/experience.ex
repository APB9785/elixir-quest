defmodule ElixirQuest.Components.Experience do
  @moduledoc """
  Helpers for running ETS queries for the Experience components
  """
  alias ETS.Set, as: Ets

  def initialize_table, do: Ets.new!(name: __MODULE__)

  def add(entity_id, experience) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.put!({entity_id, experience})
  end

  def get(entity_id) do
    table = Ets.wrap_existing!(__MODULE__)

    case Ets.get!(table, entity_id) do
      nil -> nil
      {^entity_id, experience} -> experience
    end
  end
end
