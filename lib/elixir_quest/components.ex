defmodule ElixirQuest.Components do
  @moduledoc """
  This server holds a map of lists representing "Components" in the ECS pattern.
  Systems will access a component list in order to have an index of all objects which
  contain the desired component.

  For example, if the component is "Poison", then the list will hold the ids of each
  object which is currently poisoned. Each tick, the poison system will apply damage
  to all of the objects whose ids are on the list.
  """
  use GenServer

  alias ElixirQuest.Collision
  alias ElixirQuest.Mobs
  alias ElixirQuest.Systems
  alias ETS.KeyValueSet, as: Ets
  alias Phoenix.PubSub

  require Logger

  @system_frequencies Systems.frequencies()

  def start_link(region) do
    GenServer.start_link(__MODULE__, region, name: via_tuple(region.id))
  end

  defp via_tuple(id), do: {:via, Registry, {:eq_reg, {__MODULE__, id}}}

  def init(region) do
    Logger.info("Region #{region.name}: Components initialized")
    PubSub.subscribe(EQPubSub, "tick")

    {:ok, region, {:continue, :setup}}
  end

  def handle_continue(:setup, region) do
    state = %{
      objects: Ets.wrap_existing!(:objects),
      collision_server: Collision.get_pid(region.id),
      mobs_with_target: [],
      mobs_without_target: Mobs.ids_from_region(region.id),
      player_chars: []
    }

    Logger.info("Region #{region.name}: Components set up")

    {:noreply, state}
  end

  def handle_info({:tick, tick}, state) do
    # TODO: make this async

    Enum.each(@system_frequencies, fn {system, frequency} ->
      if rem(tick, frequency) == 0 do
        apply(Systems, system, [state])
      end
    end)

    {:noreply, state}
  end
end
