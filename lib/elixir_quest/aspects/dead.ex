defmodule ElixirQuest.Aspects.Dead do
  @moduledoc """
  When an entity is going to die (usually from dropping to zero hp or below), the Dead
  component is added.  This allows all Systems for this tick to finish executing before
  the entity is killed.
  """
  use ECSx.Aspect,
    schema: {:entity_id}
end
