defmodule ElixirQuest.Systems.Respawn do
  use ECSx.System,
    period: 100

  alias ElixirQuest.Aspects.Dead
  alias ElixirQuest.Aspects.Respawn
  alias ElixirQuest.Mobs

  def run do
    now = NaiveDateTime.utc_now()
    respawns = Respawn.get_all()

    Enum.each(respawns, fn %{entity_id: entity_id, respawn_at: respawn_at} ->
      if NaiveDateTime.compare(respawn_at, now) == :lt do
        entity_id
        |> tap(&Respawn.remove_component/1)
        |> tap(&Dead.remove_component/1)
        |> Mobs.get!()
        |> Mobs.spawn()
      end
    end)
  end
end
