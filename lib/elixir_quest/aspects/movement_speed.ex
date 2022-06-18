defmodule ElixirQuest.Aspects.MovementSpeed do
  @moduledoc """
  Entities capable of movement have a MovementSpeed component.
  The speed is measured in milliseconds between moves.
  """
  use ECSx.Aspect,
    schema: {:entity_id, :movement_speed}

  alias ETS.Set, as: Ets

  def update(entity_id, new_movement_speed) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.update_element!(entity_id, {2, new_movement_speed})
  end
end
