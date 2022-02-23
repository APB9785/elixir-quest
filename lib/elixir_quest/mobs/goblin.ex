defmodule ElixirQuest.Mobs.Goblin do
  @moduledoc """
  Goblin mob for Quest game.
  """
  alias ElixirQuest.Mobs.Mob

  def new(level, region, {x_pos, y_pos}) do
    hp = max_hp(level)

    %Mob{
      name: "Goblin",
      level: level,
      region: region,
      max_hp: hp,
      x_pos: x_pos,
      y_pos: y_pos,
      aggro_range: 3
    }
  end

  defp max_hp(level) do
    level * 8 + 20
  end
end
