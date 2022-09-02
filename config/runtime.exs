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
    System.get_env("MITRAVIAN__MEDUSA_MODELDIR", "~/Proyectos/mytravian/apps/medusa/priv/"),
  n_consumers: System.get_env("MITRAVIAN__MEDUSA_NCONSUMERS", "2") |> String.to_integer()

config :collector,
  root_folder: System.get_env("MITRAVIAN_ROOTFOLDER", "/tmp/travian_folder"),
  collection_hour: Time.new!(3, 0, 0)

# config :medusa,
#   model_dir: System.fetch_env!("MITRAVIAN__MEDUSA_MODEL_DIR")

# config :prediction_bank,
#   remove_hour: Time.new!(
#     System.fetch_env!("MITRAVIAN__COLLECTION_HOUR") |> String.to_integer(),
#     System.fetch_env!("MITRAVIAN__COLLECTION_MINUTE") |> String.to_integer(),
#     System.fetch_env!("MITRAVIAN__COLLECTION_SECOND") |> String.to_integer())
