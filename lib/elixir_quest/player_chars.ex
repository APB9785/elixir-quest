defmodule ElixirQuest.PlayerChars do
  @moduledoc """
  Functions for working with player characters.
  """
  import Ecto.Query

  alias ElixirQuest.PlayerChars.PlayerChar, as: PC
  alias ElixirQuest.Repo

  require Logger

  def new!(attrs) do
    %PC{}
    |> PC.changeset(attrs)
    |> Repo.insert!()
  end

  # Temporary lookup until accounts are setup (then id will be read from accounts table)
  def get_by_name(name) do
    Repo.one(
      from PC,
        where: [name: ^name]
    )
  end

  def load!(id), do: Repo.get!(PC, id)

  def save(pc_id, attrs) do
    %PC{id: pc_id}
    |> PC.changeset(attrs)
    |> Repo.update!()
  end
end
