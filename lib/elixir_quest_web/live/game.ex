defmodule ElixirQuestWeb.Game do
  @moduledoc false
  use ElixirQuestWeb, :live_view

  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.PlayerChars
  alias ElixirQuest.PlayerChars.PlayerChar
  # alias ElixirQuest.RegionManager
  # alias ElixirQuest.Regions.Region
  alias ElixirQuest.Utils
  alias Phoenix.PubSub

  @movement_cooldown 25

  def mount(_, _, socket) do
    socket =
      if connected?(socket) do
        region = "cave"
        pc_name = "dude"
        # Register for the PubSub to receive server ticks
        PubSub.subscribe(EQPubSub, "tick")

        # Get region info
        objects = Ets.wrap_existing!(:objects)
        location_index = Ets.wrap_existing!(:location_index)
        collision_server = Collision.get_pid(region)

        # Temporary id lookup until accounts are setup (then id will be read from accounts table)
        player_id = PlayerChar.name_to_id(pc_name)

        pc = PlayerChars.spawn(player_id, objects, collision_server)

        assign(socket,
          objects: objects,
          collision: collision_server,
          player: pc,
          location_index: location_index
        )
      else
        assign(socket, objects: nil, collision: nil, player: nil, location_index: nil)
      end

    {:ok, assign(socket, cells: nil, move_cooldown: false)}
  end

  def handle_event("move", _params, %{assigns: %{move_cooldown: true}} = socket) do
    {:noreply, socket}
  end

  def handle_event("move", %{"key" => key}, socket) do
    %{assigns: %{collision: collision_server, player: pc}} = socket

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
    Process.send_after(self(), :move_cooled, @movement_cooldown)

    {:noreply, assign(socket, move_cooldown: true)}
  end

  def handle_info({:tick, _tick}, socket) do
    # TODO: framerate reduction option?
    %{assigns: %{player: player, objects: objects, location_index: location_index}} = socket

    fresh_player = ETS.KeyValueSet.get!(objects, player.id)

    fresh_cells =
      {fresh_player.x_pos, fresh_player.y_pos}
      |> Utils.calculate_nearby_coords()
      |> Enum.map(&Utils.get_location_contents(&1, objects, location_index))

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
