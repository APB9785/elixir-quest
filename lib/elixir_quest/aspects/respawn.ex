defmodule ElixirQuest.Aspects.Respawn do
  @moduledoc """
  When a Mob entity dies, it will get a Respawn component, which holds
  the timestamp for when the entity should respawn.
  """
  use ECSx.Aspect,
    schema: {:entity_id, :respawn_at}

  # Hardcoding this value is temporary
  @mob_respawn_seconds 30

  def add_now(entity_id) do
    now = NaiveDateTime.utc_now()
    # Eventually we probably want to pull this from the database too
    respawn_at = NaiveDateTime.add(now, @mob_respawn_seconds)

    add_component(entity_id: entity_id, respawn_at: respawn_at)
  end
end
