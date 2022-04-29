defmodule ElixirQuest.Components.Moving do
  @moduledoc """
  Helpers for running ETS queries for the Moving components
  """
  alias ETS.Set, as: Ets

  def initialize_table, do: Ets.new!(name: __MODULE__)
end
