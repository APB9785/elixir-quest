defmodule ElixirQuest.Aspects.PlayerChar do
  @moduledoc """
  The PlayerChar component simply tags an entity as a PC.
  """
  use ECSx.Aspect,
    schema: {:entity_id}
end
