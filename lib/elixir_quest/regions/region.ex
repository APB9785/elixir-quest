defmodule ElixirQuest.Regions.Region do
  @moduledoc """
  The %Region{} struct and GenServer.
  """
  use GenServer

  alias ElixirQuest.Mobs
  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.PlayerChars.PlayerChar
  alias ElixirQuest.Regions
  alias Phoenix.PubSub

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  defp via_tuple(name), do: {:via, Registry, {:region_registry, name}}

  def init(name) do
    IO.puts("Region #{name}: Initialized.")
    empty_state = %{name: name}

    {:ok, empty_state, {:continue, :load_map}}
  end

  def handle_continue(:load_map, %{name: name} = state) do
    Process.send_after(self(), :tick, 50)
    Process.send_after(self(), :mobs_move, 1000)
    Process.send_after(self(), :aggro, 1000)

    map = Regions.map(name)
    boundaries = Regions.boundaries(map)
    IO.puts("Region #{name}: Map + boundaries loaded")

    mobs = Regions.spawn_mobs(name)
    objects = %{mobs: mobs, players: %{}}
    IO.puts("Region #{name}: mobs loaded")

    loaded = Map.merge(state, %{map: map, boundaries: boundaries, objects: objects})

    {:noreply, loaded}
  end

  # Collision detection
  def handle_cast({:move, direction, player}, state) do
    {:noreply, Regions.move_object(state, player, direction)}
  end

  # This will handle all new players joining from other regions.
  def handle_cast({:entry, %PlayerChar{} = player}, state) do
    {:noreply, update_in(state.objects.players, &Map.put(&1, player.id, player))}
  end

  # This handles mob spawns
  def handle_cast({:entry, %Mob{} = mob}, state) do
    {:noreply, update_in(state.objects.mobs, &Map.put(&1, mob.id, mob))}
  end

  # Broadcast the region state to each player
  def handle_info(:tick, state) do
    Process.send_after(self(), :tick, 50)
    PubSub.broadcast(EQPubSub, "region:cave", {:tick, state})
    {:noreply, state}
  end

  # This will move mobs toward their targets
  def handle_info(:mobs_move, state) do
    Process.send_after(self(), :mobs_move, 1000)
    {:noreply, Mobs.move(state)}
  end

  # This will aggro mobs to nearby players
  def handle_info(:aggro, state) do
    Process.send_after(self(), :aggro, 1000)
    {:noreply, Mobs.aggro(state)}
  end
end
