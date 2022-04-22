defmodule ElixirQuest.Logs do
  @moduledoc """
  Functions for generating action logs.
  """
  alias ElixirQuest.Components

  alias Phoenix.PubSub

  def make_id do
    now = NaiveDateTime.utc_now()
    NaiveDateTime.to_iso8601(now, :basic)
  end

  def broadcast(log), do: PubSub.broadcast(EQPubSub, "logs", {:log_entry, log})

  def from_attack(id, target_id, damage) do
    self_name = Components.get(:name, id)
    target_name = Components.get(:name, target_id)

    %{
      id: make_id(),
      message: "#{self_name} attacks #{target_name} for #{damage} damage."
    }
  end

  def from_spawn(name) do
    %{
      id: make_id(),
      message: "#{name} spawned."
    }
  end

  def from_death(id) do
    name = Components.get(:name, id)

    %{
      id: make_id(),
      message: "#{name} died."
    }
  end
end
