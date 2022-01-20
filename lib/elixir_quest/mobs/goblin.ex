defmodule ElixirQuest.Mobs.Goblin do
  @moduledoc """
  Goblin mob for Quest game.
  """
  alias ElixirQuest.Mobs.Mob

  def new(level, location) do
    hp = max_hp(level)

    %Mob{
      name: "Goblin",
      type: __MODULE__,
      level: level,
      max_hp: hp,
      current_hp: hp,
      status: :alive,
      location: location,
      wander: 0,
      target: nil,
      aggro_range: 3
    }
  end

  defp max_hp(level) do
    level * 8 + 20
  end

  def wander(%Mob{name: "Goblin", wander: wander}) do
    case wander do
      0 -> {:west, 1}
      1 -> {:west, 2}
      2 -> {:east, 3}
      3 -> {:east, 0}
    end
  end
end
