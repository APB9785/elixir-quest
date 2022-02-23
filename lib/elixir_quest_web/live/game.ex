defmodule ElixirQuestWeb.Game do
  @moduledoc false
  use ElixirQuestWeb, :live_view

  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.PlayerChars
  alias ElixirQuest.PlayerChars.PlayerChar
  alias ElixirQuest.RegionManager
  alias ElixirQuest.Regions.Region
  alias ElixirQuest.Utils
  alias Phoenix.PubSub

  @tick_rate 25

  def mount(_, _, socket) do
    socket =
      if connected?(socket) do
        # Register for the PubSub to receive server ticks
        PubSub.subscribe(EQPubSub, "region:cave")

        # Get region info
        region = RegionManager.join("cave")

        # Temporary id lookup until accounts are setup (then id will be read from accounts table)
        player_id = PlayerChar.name_to_id("dude")

        player = PlayerChars.spawn(player_id, region.objects, region.collision_server)

        # Eventually replace this with more robust ticker?
        :timer.send_interval(@tick_rate, :tick)

        assign(socket, region: region, player: player)
      else
        assign(socket, region: nil, player: nil)
      end

    {:ok, assign(socket, cells: nil, move_cooldown: false)}
  end

  def handle_event("move", _params, %{assigns: %{move_cooldown: true}} = socket) do
    {:noreply, socket}
  end

  def handle_event("move", %{"key" => key}, socket) do
    %{assigns: %{region: %Region{collision_server: collision_server}, player: pc}} = socket

    direction =
      cond do
        key == "ArrowLeft" or key == "a" -> :west
        key == "ArrowRight" or key == "d" -> :east
        key == "ArrowUp" or key == "w" -> :north
        key == "ArrowDown" or key == "s" -> :south
        :otherwise -> :error
      end

    PlayerChars.move(pc, direction, collision_server)

    # The cooldown prevents corrupting the ETS tables with extremely rapid movement input
    Process.send_after(self(), :move_cooled, @tick_rate)

    {:noreply, assign(socket, move_cooldown: true)}
  end

  def handle_info(:tick, %{assigns: %{player: player, region: region}} = socket) do
    fresh_player = ETS.KeyValueSet.get!(region.objects, player.id)

    fresh_cells =
      {fresh_player.x_pos, fresh_player.y_pos}
      |> Utils.calculate_nearby_coords()
      |> Enum.map(&Utils.get_location_contents(&1, region))

    {:noreply, assign(socket, cells: fresh_cells, player: fresh_player)}
  end

  def handle_info(:move_cooled, socket) do
    {:noreply, assign(socket, move_cooldown: false)}
  end

  defp render_cell(cell) do
    image_filename =
      case cell do
        :empty -> "background.png"
        :rock -> "rock_mount.png"
        %Mob{name: "Goblin"} -> "goblin.png"
        %PlayerChar{} -> "knight.png"
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
