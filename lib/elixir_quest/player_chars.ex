defmodule ElixirQuest.PlayerChars do
  @moduledoc """
  Functions for working with player characters.
  """
  alias ElixirQuest.Collision
  alias ElixirQuest.PlayerChars.PlayerChar
  alias ElixirQuest.Utils

  require Logger

  @doc """
  Given a PC id, loads that PC from the database into a region's ETS tables.
  If the PC is already present in the table, returns it from memory without a DB query.
  """
  def spawn(id, objects, collision_server) do
    case ETS.KeyValueSet.get!(objects, id) do
      nil ->
        pc = PlayerChar.load(id)
        GenServer.cast(collision_server, {:spawn, pc})
        Logger.info("#{pc.region}: Player #{pc.name} spawned")
        pc

      %PlayerChar{} = pc ->
        Logger.info("#{pc.region}: Player #{pc.name} already exists")
        pc
    end
  end

  def move(_, :error, _), do: :ok

  def move(%PlayerChar{id: pc_id, x_pos: x, y_pos: y}, direction, collision_server)
      when direction in ~w(north south east west)a and is_pid(collision_server) do
    destination = Utils.adjacent_coord({x, y}, direction)
    GenServer.cast(collision_server, {:move, pc_id, {x, y}, destination})
  end
end
