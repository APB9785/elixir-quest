defmodule ElixirQuest.Aspects.Cooldown do
  @moduledoc """
  Whenever an entity takes an action, it gains a Cooldown component, which stores the
  timestamp of when the cooldown expires and the action may be taken again.
  """
  use ECSx.Aspect,
    schema: {:entity_id, :action, :timestamp},
    table_type: :bag

  alias ETS.Bag, as: Ets

  def remove(entity_id, action) do
    __MODULE__
    |> Ets.wrap_existing!()
    |> Ets.match_delete!({entity_id, action, :_})
  end

  def ready?(entity_id, action) do
    table = Ets.wrap_existing!(__MODULE__)

    case Ets.match_object!(table, {entity_id, action, :_}, 1) do
      {[], :end_of_table} -> true
      {[_], _} -> false
    end
  end
end
