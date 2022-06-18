defmodule ElixirQuest.Aspects.Name do
  @moduledoc """
  All entities which can be targeted should have a Name component with the name to be displayed.

  Images currently don't change so this table's traffic is almost 100% reads.
  """
  use ECSx.Aspect,
    schema: {:entity_id, :name},
    read_concurrency: true
end
