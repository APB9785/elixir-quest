defmodule ElixirQuest.PlayerChars.PlayerChar do
  @moduledoc """
  The %PlayerChar{} struct.
  """
  alias ElixirQuest.Regions

  defstruct [
    :id,
    :name,
    :level,
    :experience,
    :max_hp,
    :current_hp,
    :status,
    :location,
    :region_name,
    :region_pid,
    :weapon,
    :target
  ]

  def new(name) do
    region_name = "cave"
    [{region_pid, _}] = Registry.lookup(:region_registry, region_name)

    player_char = %__MODULE__{
      id: 1,
      name: name,
      level: 1,
      experience: 0,
      max_hp: 50,
      current_hp: 50,
      status: :alive,
      location: {5, 1},
      region_name: region_name,
      region_pid: region_pid,
      target: nil
    }

    Regions.spawn_in(region_pid, player_char)

    IO.puts("Player #{name} spawned.")

    player_char
  end
end
