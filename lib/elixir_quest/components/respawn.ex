defmodule ElixirQuest.Components.Respawn do
  @moduledoc """
  When a Mob entity dies, it will get a Respawn component, which holds
  the timestamp for when the entity should respawn.
  """
  alias ETS.Set, as: Ets

  # Hardcoding this value is temporary
  @mob_respawn_seconds 30

  def initialize_table, do: Ets.new!(name: __MODULE__)

  def add(entity_id) do
    now = NaiveDateTime.utc_now()
    # Eventually we probably want to pull this from the database too
    respawn_at = NaiveDateTime.add(now, @mob_respawn_seconds)

    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.put!({entity_id, respawn_at})
  end

  def get(entity_id) do
    table = Ets.wrap_existing!(__MODULE__)

    case Ets.get!(table, entity_id) do
      nil -> nil
      {^entity_id, respawn_at} -> respawn_at
    end
  end

  def get_all do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.to_list!()
  end

  def remove(entity_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.delete!(entity_id)
  end

  def has_component?(entity_id) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.has_key!(entity_id)
  end
end
