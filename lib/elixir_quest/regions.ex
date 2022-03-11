defmodule ElixirQuest.Regions do
  @moduledoc """
  Functions for working with Regions.
  """
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
end
