defmodule ElixirQuest.Objects do
  @moduledoc """
  Functions for working with the objects table.
  """
  alias ETS.KeyValueSet, as: Ets

  # READ-ONLY: MAY BE CALLED BY ANY PROCESS

  def get(objects, id), do: Ets.get!(objects, id)

  # WRITES: MAY ONLY BE CALLED BY MANAGER

  def update_position(objects, id, {x, y}) do
    object = Ets.get!(objects, id)
    updated_object = %{object | x_pos: x, y_pos: y}

    Ets.put!(objects, id, updated_object)
  end

  def spawn(objects, object), do: Ets.put(objects, object.id, object)
end
