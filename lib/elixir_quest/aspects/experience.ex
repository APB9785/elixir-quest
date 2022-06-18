defmodule ElixirQuest.Aspects.Experience do
  @moduledoc """
  PC entities each have an Experience component to hold their current xp total.
  """
  use ECSx.Aspect,
    schema: {:entity_id, :experience}
end
