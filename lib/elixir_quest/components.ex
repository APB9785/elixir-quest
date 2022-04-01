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

  # alias ElixirQuest.Mobs
  alias ElixirQuest.Systems
  alias ETS.Set, as: Ets
  alias Phoenix.PubSub

  require Logger

  @system_frequencies Systems.frequencies()

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: {:via, Registry, {:eq_reg, __MODULE__}})
  end

  def init(_) do
    Logger.info("Components initialized")
    PubSub.subscribe(EQPubSub, "tick")

    state = %{
      attacking: %{}
    }

    {:ok, state}
  end

  def handle_cast({:start_attack, attacker_id}, state) do
    {:noreply, Map.update!(state, :attacking, &Map.put_new(&1, attacker_id, 0))}
  end

  def handle_cast({:stop_attack, attacker_id}, state) do
    {:noreply, Map.update!(state, :attacking, &Map.delete(&1, attacker_id))}
  end

  def handle_cast({:update_attackers, updated_attackers}, state) do
    {:noreply, Map.put(state, :attacking, updated_attackers)}
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

  ## API

  @doc """
  Update the attackers component after a round of attacks.
  """
  @spec update_attackers(map()) :: :ok
  def update_attackers(updated_attackers) do
    components = {:via, Registry, {:eq_reg, __MODULE__}}
    GenServer.cast(components, {:update_attackers, updated_attackers})
  end
end
