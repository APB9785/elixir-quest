defmodule ElixirQuest.Aspects.Moving do
  @moduledoc """
  Entities currently moving have a Moving component, which holds the direction of movement.
  """
  use ECSx.Aspect,
    schema: {:entity_id, :direction}
end
