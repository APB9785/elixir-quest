defmodule ElixirQuest.Objects do
  @moduledoc """
  Functions for working with the objects table.
  """
  alias ElixirQuest.Mobs.Mob
  alias ElixirQuest.PlayerChars.PlayerChar
  alias ElixirQuest.Regions.Region
  alias ETS.Set, as: Ets

  # READ-ONLY: MAY BE CALLED BY ANY PROCESS

  @doc """
  Fetch an object by ID, then convert it into its appropriate struct.
  """
  def get_by_id(id) do
    objects = Ets.wrap_existing!(:objects)

    case Ets.get!(objects, id) do
      nil -> nil
      result -> from_ets(result)
    end
  end

  def get_by_location({x, y}, region_id) do
    objects = Ets.wrap_existing!(:objects)
    match = {:_, :_, :_, :_, :_, :_, :_, x, y, :_, region_id}

    case Ets.match_object!(objects, match, 1) do
      {[], :end_of_table} -> :empty
      {[result], _} -> from_ets(result)
    end
  end

  def get_all_mobs_with_target do
    match_spec = [
      {{:_, Mob, :_, :_, :_, :_, :_, :_, :_, :"$1", :_}, [not: {:==, :"$1", nil}], [:"$_"]}
    ]

    :objects
    |> Ets.wrap_existing!()
    |> Ets.select!(match_spec)
    |> Enum.map(&Mob.from_ets/1)
  end

  def get_all_mobs_without_target do
    :objects
    |> Ets.wrap_existing!()
    |> Ets.match_object!({:_, Mob, :_, :_, :_, :_, :_, :_, :_, nil, :_})
    |> Enum.map(&Mob.from_ets/1)
  end

  def get_all_pcs do
    :objects
    |> Ets.wrap_existing!()
    |> Ets.match_object!({:_, PlayerChar, :_, :_, :_, :_, :_, :_, :_, :_, :_})
    |> Enum.map(&PlayerChar.from_ets/1)
  end

  # WRITES: MAY ONLY BE CALLED BY MANAGER

  def update_position(objects, object, {x, y}) do
    element_spec = [{8, x}, {9, y}]

    case object do
      %Mob{} -> Ets.update_element!(objects, object.id, element_spec)
      %PlayerChar{} -> Ets.update_element!(objects, object.id, element_spec)
    end
  end

  def spawn(objects, %Mob{} = mob), do: Ets.put(objects, Mob.to_ets(mob))
  def spawn(objects, %PlayerChar{} = pc), do: Ets.put(objects, PlayerChar.to_ets(pc))

  def assign_target(objects, object_id, target_id) do
    Ets.update_element!(objects, object_id, {10, target_id})
  end

  # This will read the raw_map of a region and add the boundaries to the objects table.
  # The value will be set to `:rock`.
  def load_boundaries(objects, %Region{raw_map: raw_map, id: id}) do
    raw_map
    |> String.graphemes()
    |> parse_txt(objects, id)
  end

  defp parse_txt(map, objects, region_id, x \\ 0, y \\ 0)
  defp parse_txt([], _, _, _, _), do: :ok

  defp parse_txt(["\n" | rest], objects, region_id, _x, y),
    do: parse_txt(rest, objects, region_id, 0, y + 1)

  defp parse_txt([" " | rest], objects, region_id, x, y),
    do: parse_txt(rest, objects, region_id, x + 1, y)

  defp parse_txt(["#" | rest], objects, region_id, x, y) do
    rock = {Ecto.UUID.generate(), :rock, "rock", nil, nil, nil, nil, x, y, nil, region_id}

    Ets.put!(objects, rock)
    parse_txt(rest, objects, region_id, x + 1, y)
  end

  # HELPERS

  defp from_ets(object) do
    case elem(object, 1) do
      :rock -> %{id: elem(object, 0), name: "rock"}
      type -> apply(type, :from_ets, [object])
    end
  end
end
