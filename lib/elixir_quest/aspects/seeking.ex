defmodule ElixirQuest.Aspects.Seeking do
  @moduledoc """
  When a mob is aggro'ed to a PC, it will gain a Seeking component, which marks that it
  should cease its default behavior and instead move towards its target and attack.
  """
  use ECSx.Aspect,
    schema: {:entity_id, :target_id}

  def has_target?(entity_id) do
    case get(entity_id) do
      nil -> false
      _ -> true
    end
  end
end
