defmodule ElixirQuest.Components.Image do
  @moduledoc """
  Helpers for running ETS queries for the Image components
  """
  alias ETS.Set, as: Ets

  def initialize_table, do: Ets.new!(name: __MODULE__)

  def add(entity_id, image_filename) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.put!({entity_id, image_filename})
  end

  def get(entity_id) do
    table = Ets.wrap_existing!(__MODULE__)

    case Ets.get!(table, entity_id) do
      nil -> nil
      {^entity_id, image_filename} -> image_filename
    end
  end

  def remove(entity_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.delete!(entity_id)
  end
end
