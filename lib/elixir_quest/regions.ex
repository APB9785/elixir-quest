defmodule ElixirQuest.Regions do
  @moduledoc """
  Functions for working with Regions.
  """
  alias ElixirQuest.Components
  alias ElixirQuest.Regions.Region
  alias ElixirQuest.Repo

  def new!(name, raw_map) do
    %Region{}
    |> Region.changeset(%{name: name, raw_map: raw_map})
    |> Repo.insert!()
  end

  def load_all do
    Repo.all(Region)
  end

  # This will read the raw_map of a region and add components for the boundary entities.
  def load_boundaries(%Region{raw_map: raw_map, id: id}) do
    raw_map
    |> String.graphemes()
    |> parse_txt(id)
  end

  defp parse_txt(map, region_id, x \\ 0, y \\ 0)
  defp parse_txt([], _, _, _), do: :ok

  defp parse_txt(["\n" | rest], region_id, _x, y),
    do: parse_txt(rest, region_id, 0, y + 1)

  defp parse_txt([" " | rest], region_id, x, y),
    do: parse_txt(rest, region_id, x + 1, y)

  defp parse_txt(["#" | rest], region_id, x, y) do
    id = Ecto.UUID.generate()
    Components.add(:location, id, region_id, {x, y})
    Components.add(:image, id, "rock_mount.png")
    parse_txt(rest, region_id, x + 1, y)
  end
end
