defmodule ElixirQuest.Seek do
  @moduledoc """
  A system for moving mobs towards their targets.
  """
  use GenServer

  alias ElixirQuest.Mobs
  alias ElixirQuest.RegionManager

  require Logger

  @tick_rate 1000

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  defp via_tuple(name), do: {:via, Registry, {:eq_reg, {:seek, name}}}

  def init(name) do
    Logger.info("Region #{name}: Seek system initialized")
    {:ok, name, {:continue, :setup}}
  end

  def handle_continue(:setup, name) do
    mobs = Mobs.load_from_region(name)
    # mob_ids = Enum.reduce(mobs, MapSet.new(), fn mob, acc -> MapSet.put(acc, mob.id) end)
    # I think we will always enumerate the whole list - if not maybe change back
    mob_ids = Enum.map(mobs, & &1.id)

    # Get region info
    region = RegionManager.join("cave")

    :timer.send_interval(@tick_rate, :tick)

    Logger.info("Region #{name}: Seek system set up successfully")

    {:noreply, %{region: region, mob_ids: mob_ids}}
  end

  def handle_info(:tick, %{region: region, mob_ids: mob_ids} = state) do
    Enum.each(mob_ids, &Mobs.seek_or_wander(&1, region))
    {:noreply, state}
  end
end
