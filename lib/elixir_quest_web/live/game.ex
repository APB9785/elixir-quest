defmodule ElixirQuestWeb.Game do
  @moduledoc false
  use ElixirQuestWeb, :live_view

  alias ElixirQuest.PlayerChars.PlayerChar

  def mount(_, _, socket) do
    [{region_pid, _}] = Registry.lookup(:region_registry, "cave")
    player = PlayerChar.new("dude")

    socket = assign(socket, cells: nil, region: region_pid, player: player)

    Process.send_after(self(), :tick, 100)

    {:ok, socket}
  end

  def handle_event("move", %{"direction" => direction}, socket) do
    GenServer.cast(socket.assigns.player, {:move, convert(direction)})

    {:noreply, socket}
  end

  def handle_event("move", %{"key" => key}, socket) do
    %{assigns: %{region: region_pid, player: player_char}} = socket

    cond do
      key == "ArrowLeft" or key == "a" ->
        GenServer.cast(region_pid, {:move, :west, player_char})

      key == "ArrowRight" or key == "d" ->
        GenServer.cast(region_pid, {:move, :east, player_char})

      key == "ArrowUp" or key == "w" ->
        GenServer.cast(region_pid, {:move, :north, player_char})

      key == "ArrowDown" or key == "s" ->
        GenServer.cast(region_pid, {:move, :south, player_char})

      true ->
        nil
    end

    {:noreply, socket}
  end

  def handle_call(:get_location, _from, socket) do
    {:reply, socket.assigns.player.location, socket}
  end

  def handle_info(:tick, socket) do
    {cells, player} = GenServer.call(socket.assigns.region, {:tick, socket.assigns.player.name})

    Process.send_after(self(), :tick, 50)

    {:noreply, assign(socket, cells: cells, player: player)}
  end

  defp convert(direction) do
    case direction do
      "up" -> :north
      "down" -> :south
      "left" -> :west
      "right" -> :east
    end
  end

  defp render_cell(cell) do
    image_filename =
      case cell do
        " " -> "background.png"
        "#" -> "rock_mount.png"
        "+" -> "goblin.png"
        "@" -> "knight.png"
      end

    path = Path.join("/images", image_filename)

    ElixirQuestWeb.Endpoint
    |> Routes.static_path(path)
    |> img_tag(class: "object-scale-down min-w-0 min-h-0 h-fit max-w-full max-h-full")
  end
end
