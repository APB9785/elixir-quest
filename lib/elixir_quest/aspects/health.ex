defmodule ElixirQuest.Aspects.Health do
  @moduledoc """
  All living entities have a Health component which tracks their current hp and maximum hp.
  """
  use ECSx.Aspect,
    schema: {:entity_id, :current_hp, :max_hp}

  alias ETS.Set, as: Ets

  @doc """
  Decrements the given entity's current hp.
  """
  def decrease_current_hp(entity_id, amount) do
    %{current_hp: current_hp} = get_component(entity_id)
    table = Ets.wrap_existing!(__MODULE__)

    new_hp = current_hp - amount

    Ets.update_element!(table, entity_id, {2, new_hp})
    Phoenix.PubSub.broadcast(EQPubSub, "entity:#{entity_id}", {:hp_change, entity_id, new_hp})

    new_hp
  end
end
