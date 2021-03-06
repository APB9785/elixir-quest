# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :elixir_quest,
  ecto_repos: [ElixirQuest.Repo]

# Configures the endpoint
config :elixir_quest, ElixirQuestWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: ElixirQuestWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: EQPubSub,
  live_view: [signing_salt: "rYQuInSH"]

# Configures the repo
config :elixir_quest, ElixirQuest.Repo, migration_primary_key: [type: :binary_id]

# Configures the mailer API module
config :elixir_quest, ElixirQuest.Mailer, api: ElixirQuest.Mailer.Swoosh

# Configures the mailer
config :elixir_quest, ElixirQuest.Mailer.Swoosh,
  adapter: Swoosh.Adapters.Postmark,
  api_key: {:system, "POSTMARK_API_KEY"}

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.18",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tailwind,
  version: "3.0.10",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
