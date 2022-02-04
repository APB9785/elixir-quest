defmodule ElixirQuestWeb.Game do
  @moduledoc false
  use ElixirQuestWeb, :live_view

  alias ElixirQuest.PlayerChars.PlayerChar
  alias ElixirQuestWeb.Display
  alias Phoenix.PubSub

  def mount(_, _, socket) do
    socket =
      if connected?(socket) do
        PubSub.subscribe(EQPubSub, "region:cave")

        [{region_pid, _}] = Registry.lookup(:region_registry, "cave")
        player = PlayerChar.new("dude")

        assign(socket, region: region_pid, player: player)
      else
        assign(socket, region: nil, player: nil)
      end

    {:ok, assign(socket, cells: nil)}
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

  def handle_info({:tick, new_region}, %{assigns: %{player: player}} = socket) do
    fresh_player =
      new_region.objects.players
      |> Map.values()
      |> Enum.find(&(&1.id == player.id))

    fresh_cells = Display.print(new_region)

    {:noreply, assign(socket, cells: fresh_cells, player: fresh_player)}
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

  defp hp_percent(%PlayerChar{max_hp: max, current_hp: current}) do
    current / max * 100
  end
end
