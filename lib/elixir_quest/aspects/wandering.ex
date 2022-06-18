defmodule ElixirQuest.Aspects.Wandering do
  @moduledoc """
  This component is added to any mobs which are not currently aggro'ed to a target.
  """
  use ECSx.Aspect,
    schema: {:entity_id}
end
