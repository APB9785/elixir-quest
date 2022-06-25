defmodule ElixirQuest.Systems.Death do
  use ECSx.System

  alias ElixirQuest.Aspects.Aggro
  alias ElixirQuest.Aspects.Attacking
  alias ElixirQuest.Aspects.Dead
  alias ElixirQuest.Aspects.Health
  alias ElixirQuest.Aspects.Image
  alias ElixirQuest.Aspects.Location
  alias ElixirQuest.Aspects.Moving
  alias ElixirQuest.Aspects.Name
  alias ElixirQuest.Aspects.Respawn
  alias ElixirQuest.Aspects.Seeking
  alias ElixirQuest.Aspects.Wandering
  alias ElixirQuest.Logs

  def run do
    dead = Dead.get_all()

    Enum.each(dead, fn %{entity_id: id} ->
      id
      |> Logs.from_death()
      |> Logs.broadcast()

      Location.remove_and_broadcast(id)
      Seeking.remove_component(id)
      Wandering.remove_component(id)
      Health.remove_component(id)
      Aggro.remove_component(id)
      Image.remove_component(id)
      Name.remove_component(id)
      Dead.remove_component(id)
      Moving.remove_component(id)
      Attacking.remove_component(id)

      Phoenix.PubSub.broadcast(EQPubSub, "entity:#{id}", {:death, id})

      Respawn.add_now(id)
    end)
  end
end
