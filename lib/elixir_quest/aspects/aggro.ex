defmodule ElixirQuest.Aspects.Aggro do
  @moduledoc """
  Aggressive mobs will have an Aggro component, which contains the aggro_range (distance
  from the mob in any direction) which a PC must enter to trigger the mob.
  """
  use ECSx.Aspect,
    schema: {:entity_id, :aggro_range}
end
