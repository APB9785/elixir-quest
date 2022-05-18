defmodule ElixirQuest.Components.MovementSpeed do
  @moduledoc """
  Entities capable of movement have a MovementSpeed component.
  The speed is measured in milliseconds between moves.
  """
  alias ETS.Set, as: Ets

  def initialize_table, do: Ets.new!(name: __MODULE__)

  def add(entity_id, movement_speed) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.put!({entity_id, movement_speed})
  end

  def get(entity_id) do
    table = Ets.wrap_existing!(__MODULE__)

    case Ets.get!(table, entity_id) do
      nil -> nil
      {^entity_id, movement_speed} -> movement_speed
    end
  end

  def update(entity_id, new_movement_speed) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.update_element!(entity_id, {2, new_movement_speed})
  end

  def remove(entity_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.delete!(entity_id)
  end
end
