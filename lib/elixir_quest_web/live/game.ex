defmodule ElixirQuestWeb.Game do
  @moduledoc false
  use ElixirQuestWeb, :live_view

  alias ElixirQuest.Components
  alias ElixirQuest.Logs
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
        %PlayerChar{id: id, name: name} = pc = PlayerChars.get_by_name("dude")

        spawn_pc(pc)

        # Register for the PubSub to receive server ticks and action logs.
        PubSub.subscribe(EQPubSub, "tick")
        PubSub.subscribe(EQPubSub, "logs")

        assign(socket,
          pc_id: id,
          pc_name: name,
          current_hp: pc.current_hp,
          max_hp: pc.max_hp,
          logs: [Logs.from_spawn(name)]
        )
      else
        assign(socket, pc_id: nil, pc_name: nil, current_hp: nil, max_hp: nil, logs: [])
      end

    {:ok, assign(socket, cells: nil, move_cooldown: false, target: nil, action: nil),
     temporary_assigns: [logs: []]}
  end

  def handle_event("move", _params, %{assigns: %{move_cooldown: true}} = socket) do
    {:noreply, socket}
  end

  def handle_event("move", %{"key" => key}, %{assigns: %{pc_id: pc_id}} = socket) do
    direction =
      cond do
        key == "ArrowLeft" or key == "a" -> :west
        key == "ArrowRight" or key == "d" -> :east
        key == "ArrowUp" or key == "w" -> :north
        key == "ArrowDown" or key == "s" -> :south
        :otherwise -> :error
      end

    unless direction == :error do
      {region_id, {x, y}} = Components.get(:location, pc_id)
      destination = Utils.adjacent_coord({x, y}, direction)

      Components.attempt_move(pc_id, region_id, destination)
    end

    # The cooldown prevents corrupting the ETS tables with extremely rapid movement input
    Process.send_after(self(), :move_cooled, @movement_cooldown)

    {:noreply, assign(socket, move_cooldown: true)}
  end

  def handle_event("target", %{"id" => id}, socket) do
    Components.add_target(socket.assigns.pc_id, id)
    {:noreply, socket}
  end

  def handle_event("action", %{"action" => action_param}, socket) do
    %{pc_id: id, action: previous_action} = socket.assigns

    case Utils.atomize(action_param) do
      ^previous_action ->
        Components.cancel_action(id, previous_action)
        {:noreply, assign(socket, action: nil)}

      new_action ->
        Components.begin_action(id, new_action, previous_action)
        {:noreply, assign(socket, action: new_action)}
    end
  end

  def handle_info({:tick, _tick}, %{assigns: %{pc_id: pc_id}} = socket) do
    # TODO: framerate reduction option?
    {current_hp, max_hp} = Components.get(:health, pc_id)
    {region_id, {x, y}} = Components.get(:location, pc_id)

    target =
      case Components.get(:target, pc_id) do
        nil ->
          # PC has no target
          nil

        target_id ->
          case Components.get(:health, target_id) do
            nil ->
              # No health means this is probably region boundary entity
              nil

            {current, max} ->
              # Valid target
              %{
                current_hp: current,
                max_hp: max,
                name: Components.get(:name, target_id)
              }
          end
      end

    fresh_cells =
      {x, y}
      |> Utils.calculate_nearby_coords()
      |> Enum.map(&Components.search_location(region_id, &1))

    {:noreply,
     assign(socket, cells: fresh_cells, current_hp: current_hp, max_hp: max_hp, target: target)}
  end

  def handle_info({:log_entry, entry}, socket) do
    {:noreply, assign(socket, logs: [entry])}
  end

  def handle_info(:move_cooled, socket) do
    {:noreply, assign(socket, move_cooldown: false)}
  end

  defp spawn_pc(%PlayerChar{id: id} = pc) do
    case Components.spawn_pc(pc) do
      :blocked ->
        Process.sleep(1000)
        spawn_pc(pc)

      :success ->
        id

      :already_spawned ->
        id
    end
  end

  defp render_cell(nil), do: render_cell("background.png", nil)

  defp render_cell(content_id) do
    # This is kinda hack-y, and is only here to prevent setting the target to a boundary or
    # to your own character and then trying to do something that doesn't work,
    # such as attacking it.
    # TODO: find a better way to prevent targetting boundaries/self.
    case Components.get(:image, content_id) do
      filename when filename in ~w(rock_mount.png knight.png) ->
        render_cell(filename, nil)

      other_filename ->
        render_cell(other_filename, content_id)
    end
  end

  defp render_cell(image_filename, id) do
    path = Path.join("/images", image_filename)

    ElixirQuestWeb.Endpoint
    |> Routes.static_path(path)
    |> img_tag(
      class: "object-scale-down min-w-0 min-h-0 h-fit max-w-full max-h-full",
      phx_click: JS.push("target", value: %{id: id})
    )
  end

  defp hp_percent(current, max) do
    current / max * 100
  end

  defp action_button(button_action, active_action) do
    base = "w-1/6 border border-black font-bold text-center py-4 my-4 cursor-pointer select-none"

    if active_action == button_action do
      [base, " bg-gray-300"]
    else
      base
    end
  end
end
