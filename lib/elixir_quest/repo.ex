defmodule ElixirQuest.Repo do
  use Ecto.Repo,
    otp_app: :elixir_quest,
    adapter: Ecto.Adapters.Postgres
end
