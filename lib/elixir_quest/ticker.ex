defmodule ElixirQuest.Ticker do
  @moduledoc """
  Broadcasts server ticks over PubSub, to be consumed by LiveView clients and the
  Components manager (which runs the Systems).
  """
  use GenServer

  alias ElixirQuest.Systems
  alias ElixirQuest.Utils
  alias Phoenix.PubSub

  require Logger

  @base_tick_rate 50

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(name) do
    max = final_tick()
    Logger.info("Region #{name}: Ticker initialized")
    :timer.send_interval(@base_tick_rate, :tick)
    {:ok, {0, max}}
  end

  defp final_tick do
    Systems.frequencies()
    |> Enum.map(fn {_system_name, frequency} -> frequency end)
    |> Utils.lcm()
  end

  def handle_info(:tick, {current, max}) do
    PubSub.broadcast(EQPubSub, "tick", {:tick, current})

    case current + 1 do
      ^max -> {:noreply, {0, max}}
      next -> {:noreply, {next, max}}
    end
  end
end
