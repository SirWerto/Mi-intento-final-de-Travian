# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

config :front,
  ecto_repos: [Front.Repo],
  generators: [context_app: false]

# Configures the endpoint
config :front, Front.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: Front.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Front.PubSub,
  live_view: [signing_salt: "ENYS5xbS"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/front/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :front,
  ecto_repos: [Front.Repo],
  generators: [context_app: false]

# Configures the endpoint
config :front, Front.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: Front.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Front.PubSub,
  live_view: [signing_salt: "c6bMNyBc"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/front/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]


# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# config :t_db, TDB.Repo,
#   database: "travian",
#   username: "postgres",
#   password: "postgres",
#   hostname: "localhost"

import_config "#{config_env()}.exs"
# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#
