defmodule ElixirQuest.Regions do
  @moduledoc """
  Functions for working with Regions.
  """
  alias ElixirQuest.Regions.Region

  @doc """
  This will read the raw_map from a region and add the boundaries to its location_index.
  The value will be set to `:rock`.
  """
  def load_boundaries(%Region{raw_map: raw_map, location_index: location_index}) do
    raw_map
    |> String.graphemes()
    |> parse_txt(location_index)
  end

  defp parse_txt(map, location_index, x \\ 0, y \\ 0)
  defp parse_txt([], _, _, _), do: :ok
  defp parse_txt(["\n" | rest], index, _x, y), do: parse_txt(rest, index, 0, y + 1)
  defp parse_txt([" " | rest], index, x, y), do: parse_txt(rest, index, x + 1, y)

  defp parse_txt(["#" | rest], index, x, y) do
    ETS.KeyValueSet.put!(index, {x, y}, :rock)
    parse_txt(rest, index, x + 1, y)
  end
end
