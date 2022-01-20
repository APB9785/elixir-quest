defmodule ElixirQuest.PlayerChars.PlayerChar do
  @moduledoc """
  The %PlayerChar{} struct.
  """
  alias ElixirQuest.Regions

  defstruct [
    :account_id,
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
      account_id: "123",
      name: name,
      level: 1,
      experience: 0,
      max_hp: 50,
      current_hp: 50,
      status: :alive,
      location: {5, 1},
      region_name: region_name,
      region_pid: region_pid,
      target: nil,
      pid: self()
    }

    Regions.spawn_in(region_pid, player_char)

    IO.puts("Player #{name} spawned.")

    player_char
  end

  def handle_cast({:move, direction}, %__MODULE__{location: {x, y}} = player) do
    new_location =
      case direction do
        :north -> {x, y - 1}
        :south -> {x, y + 1}
        :east -> {x + 1, y}
        :west -> {x - 1, y}
      end

    request = {:move_player, player, player.location, new_location}

    case GenServer.call(player.region_pid, request) do
      :ok -> {:noreply, Map.put(player, :location, new_location)}
      :blocked -> {:noreply, player}
    end
  end

  def handle_cast({:target, target}, player) do
    {:noreply, Map.put(player, :target, target)}
  end

  def handle_cast({:action, action, target}, player) do
    nil
  end

  def handle_call({:get, attribute}, _from, pc) when is_atom(attribute) do
    if attribute == :full_struct do
      {:reply, pc, pc}
    else
      {:reply, Map.fetch!(pc, attribute), pc}
    end
  end
end
