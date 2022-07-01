defmodule ElixirQuest.Regions do
  @moduledoc """
  Functions for working with Regions.
  """
  import Ecto.Query

  alias ElixirQuest.Aspects.Image
  alias ElixirQuest.Aspects.Location
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

  def get_spawn_region_id do
    Repo.one(from r in Region, where: r.name == "cave", select: r.id)
  end

  # This will read the raw_map of a region and add components for the boundary entities.
  # Can only be called from the Components manager due to component (ETS) table writes
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

    # Not broadcasting this because it seems like it should happen before any players join
    # If there's any problems just switch to `add_and_broadcast/4`
    Location.add_component(entity_id: id, region_id: region_id, x: x, y: y)

    Image.add_component(entity_id: id, image_filename: "rock_mount.png")
    parse_txt(rest, region_id, x + 1, y)
  end

  def load_all_boundaries do
    Enum.each(load_all(), &load_boundaries/1)
  end
end
