defmodule ElixirQuest.Mailer.Mock do
  def deliver(_, _ \\ []) do
    {:ok, %{}}
  end
end
