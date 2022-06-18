defmodule ElixirQuest.Aspects.Image do
  @moduledoc """
  Any entity which is to be rendered in the display must have an Image component which
  holds the filename for its graphic.

  Images currently don't change so this table's traffic is almost 100% reads.
  """
  use ECSx.Aspect,
    schema: {:entity_id, :image_filename},
    read_concurrency: true
end
