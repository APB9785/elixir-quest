defmodule ElixirQuest.Aspects.Attacking do
  @moduledoc """
  When an entity starts attacking, it will gain the Attacking component with a reference
  to its target.  If the target changes, then the component must be updated.
  """
  use ECSx.Aspect,
    schema: {:entity_id, :target_id}
end
