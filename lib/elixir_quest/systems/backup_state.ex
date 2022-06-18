defmodule ElixirQuest.Systems.BackupState do
  use ECSx.System,
    period: 250

  alias ElixirQuest.Aspects.PlayerChar
  alias ElixirQuest.PlayerChars

  def run do
    player_chars = PlayerChar.get_all()

    Enum.each(player_chars, fn %{entity_id: pc_id} ->
      PlayerChars.save(pc_id)
    end)
  end
end
