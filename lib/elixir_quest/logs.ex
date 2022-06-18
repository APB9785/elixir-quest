defmodule ElixirQuest.Logs do
  @moduledoc """
  Functions for generating action logs.
  """
  alias ElixirQuest.Aspects.Name
  alias Phoenix.PubSub

  def make_id do
    now = NaiveDateTime.utc_now()
    NaiveDateTime.to_iso8601(now, :basic)
  end

  def broadcast(log), do: PubSub.broadcast(EQPubSub, "logs", {:log_entry, log})

  def from_attack(id, target_id, damage) do
    self_name = Name.get_value(id, :name)
    target_name = Name.get_value(target_id, :name)

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
    name = Name.get_value(id, :name)

    %{
      id: make_id(),
      message: "#{name} died."
    }
  end
end
