defmodule ElixirQuest.Aspects.Level do
  @moduledoc """
  Most living entities will have a Level component to represent their combat power.
  """
  use ECSx.Aspect,
    schema: {:entity_id, :level}
end
