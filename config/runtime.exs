import Config

config :logger,
       :console,
       # level: System.get_env("MITRAVIAN__LOGGER_LEVEL", "info") |> String.to_atom(),
       format: "$node $date $time [$level] ($metadata) $message\n",
       metadata: [:mfa]

config :mnesia,
  dir: System.get_env("MITRAVIAN__MNESIA_DIR", "/tmp/mnesia") |> String.to_charlist()

config :medusa,
  root_folder: System.get_env("MITRAVIAN_ROOTFOLDER", "/tmp/travian_folder"),
  model_dir:
    System.get_env("MITRAVIAN__MEDUSA_MODELDIR", "~/Proyectos/MedusaPY"),
  n_consumers: System.get_env("MITRAVIAN__MEDUSA_NCONSUMERS", "2") |> String.to_integer()

config :collector,
  root_folder: System.get_env("MITRAVIAN_ROOTFOLDER", "/tmp/travian_folder"),
  collection_hour: Time.new!(3, 0, 0)

config :medusa_metrics,
  root_folder: System.get_env("MITRAVIAN_ROOTFOLDER", "/tmp/travian_folder")

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :front, Front.Endpoint,
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: secret_key_base

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint:
  #
  #     config :front, Front.Endpoint, server: true
  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :front, Front.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end

# config :medusa,
#   model_dir: System.fetch_env!("MITRAVIAN__MEDUSA_MODEL_DIR")

# config :prediction_bank,
#   remove_hour: Time.new!(
#     System.fetch_env!("MITRAVIAN__COLLECTION_HOUR") |> String.to_integer(),
#     System.fetch_env!("MITRAVIAN__COLLECTION_MINUTE") |> String.to_integer(),
#     System.fetch_env!("MITRAVIAN__COLLECTION_SECOND") |> String.to_integer())
