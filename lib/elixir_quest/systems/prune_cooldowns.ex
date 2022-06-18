defmodule ElixirQuest.Systems.PruneCooldowns do
  use ECSx.System

  alias ElixirQuest.Aspects.Cooldown

  def run do
    cooldowns = Cooldown.get_all()
    now = NaiveDateTime.utc_now()

    Enum.each(cooldowns, fn %{entity_id: entity_id, action: action, timestamp: timestamp} ->
      if NaiveDateTime.compare(now, timestamp) == :gt do
        Cooldown.remove(entity_id, action)
      end
    end)
  end
end
