defmodule ElixirQuest.Mailer do
  @moduledoc """
  Mailer API - uses Swoosh normally but in testing we use a mock instead.
  """

  @mailer Application.compile_env(:elixir_quest, __MODULE__)[:api]

  defdelegate deliver(email, config \\ []), to: @mailer
end
