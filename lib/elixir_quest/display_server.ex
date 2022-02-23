defmodule ElixirQuest.DisplayServer do
  @moduledoc """
  This server handles fetching the data from ETS, transforming it, and broadcasting it to players.

  Currently unused, LiveView processes are handling their own display.
  """
  use GenServer

  alias Phoenix.PubSub

  require Logger

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  defp via_tuple(name), do: {:via, Registry, {:eq_reg, {:display_server, name}}}

  def init(name) do
    # :timer.send_interval(50, :tick)

    {:ok, {name, 0}}
  end

  def handle_info(:tick, {name, _ticker}) do
    nil
    PubSub.broadcast(EQPubSub, "region:#{name}", {:display})
  end
end
