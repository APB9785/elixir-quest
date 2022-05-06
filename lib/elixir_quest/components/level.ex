defmodule ElixirQuest.Components.Level do
  @moduledoc """
  Most living entities will have a Level component to represent their combat power.
  """
  alias ETS.Set, as: Ets

  def initialize_table, do: Ets.new!(name: __MODULE__)

  def add(entity_id, level) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.put!({entity_id, level})
  end

  def get(entity_id) do
    table = Ets.wrap_existing!(__MODULE__)

    case Ets.get!(table, entity_id) do
      nil -> nil
      {^entity_id, level} -> level
    end
  end
end
