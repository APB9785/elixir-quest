defmodule ElixirQuest.PlayerChars do
  @moduledoc """
  Functions for working with player characters.
  """
  import Ecto.Query

  alias ElixirQuest.PlayerChars.PlayerChar
  alias ElixirQuest.Repo

  require Logger

  def new!(attrs) do
    %PlayerChar{}
    |> PlayerChar.changeset(attrs)
    |> Repo.insert!()
  end

  # Temporary lookup until accounts are setup (then id will be read from accounts table)
  def get_by_name(name) do
    Repo.one(
      from PlayerChar,
        where: [name: ^name]
    )
  end

  def load!(id), do: Repo.get!(PlayerChar, id)
end
