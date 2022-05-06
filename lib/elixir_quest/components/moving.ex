defmodule ElixirQuest.Components.Moving do
  @moduledoc """
  Currently unused.
  """
  alias ETS.Set, as: Ets

  def initialize_table, do: Ets.new!(name: __MODULE__)
end
