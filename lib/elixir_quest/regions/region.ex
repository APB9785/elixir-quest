defmodule ElixirQuest.Regions.Region do
  @moduledoc """
  The %Region{} struct and GenServer.
  """
  use GenServer

  alias ElixirQuest.Display
  alias ElixirQuest.Mobs
  alias ElixirQuest.PlayerChars
  alias ElixirQuest.Regions

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
    Process.send_after(self(), :seek_targets, 1000)
    Process.send_after(self(), :aggro, 1000)

    map = Regions.map(name)
    boundaries = Regions.boundaries(map)
    IO.puts("Region #{name}: Map + boundaries loaded")

    mobs = Regions.spawn_mobs(name)

    loaded = Map.merge(state, %{map: map, boundaries: boundaries, objects: mobs})

    {:noreply, loaded}
  end

  # Collision detection
  def handle_cast({:move, direction, player}, state) do
    {:noreply, PlayerChars.move(state, player, direction)}
  end

  # This will handle all new players joining from other regions.
  def handle_cast({:entry, object}, state) do
    {:noreply, Map.update!(state, :objects, &[object | &1])}
  end

  # Display
  def handle_call({:tick, player_name}, _from, state) do
    display = Display.print(state)
    player = Enum.find(state.objects, fn object -> object.name == player_name end)

    {:reply, {display, player}, state}
  end

  # This will move mobs toward their targets
  def handle_info(:seek_targets, state) do
    Process.send_after(self(), :seek_targets, 1000)
    {:noreply, Mobs.seek_targets(state)}
  end

  # This will aggro mobs to nearby players
  def handle_info(:aggro, state) do
    Process.send_after(self(), :aggro, 1000)
    {:noreply, Mobs.add_targets(state)}
  end

  # def handle_call({:move_mob, mob, prev_coord, new_coord}, _from, state) do
  #   case Map.get(state.map, new_coord) do
  #     [] ->
  #       new_state =
  #         Map.update!(state, :map, fn map ->
  #           map
  #           |> Map.update!(prev_coord, &remove_object(&1, mob))
  #           |> Map.put(new_coord, mob)
  #         end)
  #
  #       {:reply, :ok, new_state}
  #
  #     _players_or_mob_or_boundary ->
  #       {:reply, :blocked, state}
  #   end
  # end
  #
  # defp remove_object(players, player_to_remove) when is_list(players) do
  #   Enum.reject(players, &(&1.name == player_to_remove.name))
  # end
  #
  # defp remove_object(_mob, _), do: []
  #
  # defp add_object(map, %Mob{location: location} = mob) do
  #   case Map.get(map, location) do
  #     [] -> Map.put(map, location, mob)
  #     nil -> raise "SpawnError: out of bounds"
  #     "#" -> raise "SpawnError: on boundary"
  #     %Mob{} -> raise "SpawnError: on existing mob"
  #     _players -> raise "SpawnError: on existing player"
  #   end
  # end
  #
  # defp add_object(map, %PlayerChar{location: location} = player) do
  #   case Map.get(map, location) do
  #     [] -> Map.put(map, location, [player])
  #     nil -> raise "SpawnError: out of bounds"
  #     "#" -> raise "SpawnError: on boundary"
  #     %Mob{} -> raise "SpawnError: on existing mob"
  #     _players -> Map.update!(map, location, &[player | &1])
  #   end
  # end
end
