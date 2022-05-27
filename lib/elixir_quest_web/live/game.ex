defmodule ElixirQuestWeb.Game do
  @moduledoc """
  The LiveView client.
  """
  use ElixirQuestWeb, :live_view

  alias ElixirQuest.Accounts
  alias ElixirQuest.Components
  alias ElixirQuest.Components.Health
  alias ElixirQuest.Components.Image
  alias ElixirQuest.Components.Location
  alias ElixirQuest.Components.Name
  alias ElixirQuest.PlayerChars
  alias ElixirQuest.PlayerChars.PlayerChar, as: PC
  alias ElixirQuest.Utils

  alias Phoenix.LiveView.JS
  alias Phoenix.PubSub

  def mount(_params, session, socket) do
    socket =
      case Accounts.get_account_by_session_token(session["account_token"]) do
        nil ->
          # Player is logged out
          # Do logged-out stuff.
          assign(socket, account: nil, account_pc: nil)

        account ->
          # Player is logged in
          pc = PlayerChars.get_by_account(account)
          assign(socket, account: account, account_pc: pc)
      end

    {:ok,
     assign(socket,
       pc_id: nil,
       pc_name: nil,
       location: nil,
       region_map: nil,
       current_hp: nil,
       max_hp: nil,
       logs: [],
       target_id: nil,
       move_direction: nil,
       target_hp: nil,
       target_max_hp: nil,
       target_name: nil,
       attacking?: false,
       create_new_pc: false
     ), temporary_assigns: [logs: []]}
  end

  def handle_event("load_all", _params, socket) do
    %PC{
      id: pc_id,
      name: pc_name,
      x_pos: x,
      y_pos: y,
      current_hp: current_hp,
      max_hp: max_hp,
      region_id: region_id
    } = pc = socket.assigns.account_pc

    # Register for the PubSub to receive server ticks and action logs.
    PubSub.subscribe(EQPubSub, "logs")
    PubSub.subscribe(EQPubSub, "region:#{region_id}")
    PubSub.subscribe(EQPubSub, "entity:#{pc_id}")

    region_map = map_region(region_id)

    spawn_pc(pc)

    {:noreply,
     assign(socket,
       account_pc: nil,
       pc_id: pc_id,
       pc_name: pc_name,
       location: {x, y},
       current_hp: current_hp,
       max_hp: max_hp,
       region_map: region_map
     )}
  end

  def handle_event("start_move", %{"key" => key}, socket) do
    %{pc_id: pc_id, move_direction: current_direction} = socket.assigns

    parsed_input = Utils.parse_direction(key)

    case Utils.merge_directions(parsed_input, current_direction) do
      ^current_direction ->
        {:noreply, socket}

      new_direction ->
        Components.add_moving(pc_id, new_direction)
        {:noreply, assign(socket, move_direction: new_direction)}
    end
  end

  def handle_event("stop_move", %{"key" => key}, socket) do
    %{pc_id: pc_id, move_direction: current_direction} = socket.assigns

    parsed_input = Utils.parse_direction(key)

    case Utils.remove_direction(parsed_input, current_direction) do
      ^current_direction ->
        {:noreply, socket}

      nil ->
        Components.remove_moving(pc_id)
        {:noreply, assign(socket, move_direction: nil)}

      new_direction ->
        Components.add_moving(pc_id, new_direction)
        {:noreply, assign(socket, move_direction: new_direction)}
    end
  end

  def handle_event("target", %{"id" => nil}, socket) do
    Components.cancel_attack(socket.assigns.pc_id)

    {:noreply, remove_target(socket)}
  end

  def handle_event("target", %{"id" => target_id}, socket) do
    %{attacking?: attacking?, pc_id: pc_id} = socket.assigns

    PubSub.subscribe(EQPubSub, "entity:#{target_id}")
    {current_hp, max_hp} = Health.get(target_id)

    if attacking?, do: Components.begin_attack(pc_id, target_id)

    {:noreply,
     assign(socket,
       target_id: target_id,
       target_hp: current_hp,
       target_max_hp: max_hp,
       target_name: Name.get(target_id)
     )}
  end

  def handle_event("action", %{"action" => "attack"}, socket) do
    %{pc_id: id, target_id: target_id} = socket.assigns

    if socket.assigns.attacking? do
      Components.cancel_attack(id)
      {:noreply, assign(socket, attacking?: false)}
    else
      Components.begin_attack(id, target_id)
      {:noreply, assign(socket, attacking?: true)}
    end
  end

  def handle_event("create_new_pc", _, socket) do
    {:noreply, assign(socket, create_new_pc: true)}
  end

  def handle_event("cancel_create_pc", _, socket) do
    {:noreply, assign(socket, create_new_pc: false)}
  end

  def handle_info({:moved, entity_id, location, prev}, socket) do
    {{^entity_id, image}, new_region_map} = Map.pop(socket.assigns.region_map, prev)

    final_region_map = Map.put(new_region_map, location, {entity_id, image})

    socket =
      if socket.assigns.pc_id == entity_id do
        assign(socket, location: location)
      else
        socket
      end

    {:noreply, assign(socket, region_map: final_region_map)}
  end

  def handle_info({:spawned, entity_id, location}, socket) do
    image = Image.get(entity_id)
    new_region_map = Map.put(socket.assigns.region_map, location, {entity_id, image})

    {:noreply, assign(socket, region_map: new_region_map)}
  end

  def handle_info({:removed, _entity_id, location}, socket) do
    new_region_map = Map.delete(socket.assigns.region_map, location)

    {:noreply, assign(socket, region_map: new_region_map)}
  end

  def handle_info({:hp_change, entity_id, new_hp}, socket) do
    %{pc_id: pc_id, target_id: target_id} = socket.assigns

    case entity_id do
      ^pc_id -> {:noreply, assign(socket, current_hp: new_hp)}
      ^target_id -> {:noreply, assign(socket, target_hp: new_hp)}
    end
  end

  def handle_info({:max_hp_change, entity_id, new_max_hp}, socket) do
    %{pc_id: pc_id, target_id: target_id} = socket.assigns

    case entity_id do
      ^pc_id -> {:noreply, assign(socket, current_max_hp: new_max_hp)}
      ^target_id -> {:noreply, assign(socket, target_max_hp: new_max_hp)}
    end
  end

  def handle_info({:death, entity_id}, socket) do
    socket =
      if entity_id == socket.assigns.target_id do
        remove_target(socket)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info({:log_entry, entry}, socket) do
    {:noreply, assign(socket, logs: [entry])}
  end

  def handle_info(:new_pc_created, socket) do
    {:noreply,
     assign(socket,
       account_pc: PlayerChars.get_by_account(socket.assigns.account),
       create_new_pc: false
     )}
  end

  defp remove_target(socket) do
    PubSub.unsubscribe(EQPubSub, "entity:#{socket.assigns.target_id}")
    assign(socket, target_id: nil, target_hp: nil, target_max_hp: nil, target_name: nil)
  end

  defp spawn_pc(%PC{id: id} = pc) do
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

  defp nearby_cells(region_map, pc_location) do
    pc_location
    |> Utils.calculate_nearby_coords()
    |> Enum.map(&Map.get(region_map, &1, {nil, "background.png"}))
  end

  defp map_region(region_id) do
    region_id
    |> Location.get_all_from_region()
    |> Task.async_stream(&get_image/1, ordered: false)
    |> Enum.reduce(%{}, fn {:ok, {x, y, entity_id, image}}, acc ->
      Map.put(acc, {x, y}, {entity_id, image})
    end)
  end

  defp get_image({entity_id, _region_id, x, y}) do
    {x, y, entity_id, Image.get(entity_id)}
  end

  # This is kinda hack-y, and is only here to prevent setting the target to a boundary or
  # to your own character and then trying to do something that doesn't work,
  # such as attacking it.
  # TODO: find a better way to prevent targetting boundaries/self.
  defp render_cell({_entity_id, image_filename})
       when image_filename in ~w(rock_mount.png knight.png),
       do: render_cell(nil, image_filename)

  defp render_cell({entity_id, image_filename}), do: render_cell(entity_id, image_filename)

  defp render_cell(entity_id, image_filename) do
    path = Path.join("/images", image_filename)

    ElixirQuestWeb.Endpoint
    |> Routes.static_path(path)
    |> img_tag(
      class: "object-scale-down min-w-0 min-h-0 h-fit max-w-full max-h-full",
      phx_click: JS.push("target", value: %{id: entity_id})
    )
  end

  defp hp_percent(current, max) do
    current / max * 100
  end

  defp attack_button(attacking?) do
    base = "w-1/6 border border-black font-bold text-center py-4 my-4 cursor-pointer select-none"

    if attacking? do
      [base, " bg-gray-300"]
    else
      base
    end
  end
end
