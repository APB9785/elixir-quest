defmodule ElixirQuest.Mobs.Mob do
  @moduledoc """
  The %Mob{} schema.
  """

  defstruct [
    :id,
    :name,
    :level,
    :max_hp,
    :current_hp,
    :status,
    :location,
    :region_pid,
    :wander,
    :type,
    :target,
    :aggro_range
  ]

  # def start_link([mob_type, level, region, location], opts \\ []) do
  #   GenServer.start_link(__MODULE__, [mob_type, level, region, location], opts)
  # end
  #
  # def init([mob_type, level, region, location]) do
  #   s = mob_type.new(level, region, location)
  #
  #   Regions.spawn_in(region, s)
  #
  #   IO.puts("Level #{level} #{s.name} spawned.")
  #
  #   send(self(), :wander)
  #
  #   {:ok, s}
  # end

  # def handle_call({:get, attribute}, _from, mob) when is_atom(attribute) do
  #   if attribute == :full_struct do
  #     {:reply, mob, mob}
  #   else
  #     {:reply, Map.fetch!(mob, attribute), mob}
  #   end
  # end

  # Previously each mob had its own process and would use this logic to wander
  # around when not targeting a PC.  We can re-use this logic later to re-implement
  # the functionality
  #
  # def handle_info(:wander, %__MODULE__{location: {x, y}, type: type} = mob) do
  #   {direction, new_wander} = type.wander(mob)
  #
  #   new_location =
  #     case direction do
  #       :north -> {x, y - 1}
  #       :south -> {x, y + 1}
  #       :east -> {x + 1, y}
  #       :west -> {x - 1, y}
  #     end
  #
  #   request = {:move_mob, mob, mob.location, new_location}
  #
  #   Process.send_after(self(), :wander, Enum.random(1000..5000))
  #
  #   case GenServer.call(mob.region_pid, request) do
  #     :ok -> {:noreply, %{mob | location: new_location, wander: new_wander}}
  #     :blocked -> {:noreply, %{mob | wander: new_wander}}
  #   end
  # end
end
