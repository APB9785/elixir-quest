defmodule ElixirQuestWeb.Game do
  @moduledoc false
  use ElixirQuestWeb, :live_view

  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.Objects
  alias ElixirQuest.ObjectsManager
  alias ElixirQuest.PlayerChars
  alias ElixirQuest.PlayerChars.PlayerChar
  alias ElixirQuest.Utils

  alias Phoenix.LiveView.JS
  alias Phoenix.PubSub

  @movement_cooldown 25

  def mount(_, _, socket) do
    socket =
      if connected?(socket) do
        # Temporary lookup until accounts are setup (then id will be read from accounts table)
        pc =
          "dude"
          |> PlayerChars.get_by_name()
          |> spawn_pc()

        # Register for the PubSub to receive server ticks
        PubSub.subscribe(EQPubSub, "tick")

        assign(socket, player: pc)
      else
        assign(socket, player: nil)
      end

    {:ok, assign(socket, cells: nil, move_cooldown: false, target: nil)}
  end

  def handle_event("move", _params, %{assigns: %{move_cooldown: true}} = socket) do
    {:noreply, socket}
  end

  def handle_event("move", %{"key" => key}, %{assigns: %{player: pc}} = socket) do
    direction =
      cond do
        key == "ArrowLeft" or key == "a" -> :west
        key == "ArrowRight" or key == "d" -> :east
        key == "ArrowUp" or key == "w" -> :north
        key == "ArrowDown" or key == "s" -> :south
        :otherwise -> :error
      end

    PlayerChars.move(pc, direction)

    # The cooldown prevents corrupting the ETS tables with extremely rapid movement input
    Process.send_after(self(), :move_cooled, @movement_cooldown)

    {:noreply, assign(socket, move_cooldown: true)}
  end

  def handle_event("target", %{"id" => id}, socket) do
    ObjectsManager.assign_target(socket.assigns.player, id)
    {:noreply, socket}
  end

  def handle_info({:tick, _tick}, %{assigns: %{player: player}} = socket) do
    # TODO: framerate reduction option?
    fresh_player = Objects.get_by_id(player.id)

    target =
      case fresh_player.target do
        nil -> nil
        id -> Objects.get_by_id(id)
      end

    fresh_cells =
      {fresh_player.x_pos, fresh_player.y_pos}
      |> Utils.calculate_nearby_coords()
      |> Enum.map(&Objects.get_by_location(&1, fresh_player.region_id))

    {:noreply, assign(socket, cells: fresh_cells, player: fresh_player, target: target)}
  end

  def handle_info(:move_cooled, socket) do
    {:noreply, assign(socket, move_cooldown: false)}
  end

  defp spawn_pc(%PlayerChar{id: id} = pc) do
    case Objects.get_by_id(id) do
      nil -> attempt_spawn_until_successful(pc)
      %PlayerChar{} = existing -> existing
    end
  end

  defp attempt_spawn_until_successful(pc) do
    case ObjectsManager.attempt_spawn(pc) do
      {:error, :collision} ->
        Process.sleep(1000)
        attempt_spawn_until_successful(pc)

      {:ok, %PlayerChar{} = spawned} ->
        spawned
    end
  end

  defp render_cell(contents) do
    {image_filename, id} =
      case contents do
        :empty -> {"background.png", nil}
        %{name: "rock"} -> {"rock_mount.png", nil}
        %Mob{id: id, name: "Goblin"} -> {"goblin.png", id}
        %PlayerChar{id: id} -> {"knight.png", id}
      end

    path = Path.join("/images", image_filename)

    ElixirQuestWeb.Endpoint
    |> Routes.static_path(path)
    |> img_tag(
      class: "object-scale-down min-w-0 min-h-0 h-fit max-w-full max-h-full",
      phx_click: JS.push("target", value: %{id: id})
    )
  end

  defp hp_percent(%PlayerChar{max_hp: max, current_hp: current}) do
    current / max * 100
  end
end
