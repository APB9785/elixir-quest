defmodule ElixirQuest.Aspects.Equipment do
  @moduledoc """
  Any entity equipped with weapons or armor will have an Equipment component which holds
  a map of the names and stats for these items.
  """
  use ECSx.Aspect,
    schema: {:entity_id, :equipment_map}
end
