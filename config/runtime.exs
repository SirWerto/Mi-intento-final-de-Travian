import Config



config :logger,
  :console,
  level: System.get_env("MITRAVIAN__LOGGER_LEVEL", "info") |> String.to_atom(),
  format: "$node $date $time [$level] ($metadata) $message\n",
  metadata: [:mfa]

config :mnesia,
  dir: System.fetch_env!("MITRAVIAN__MNESIA_DIR") |> String.to_charlist()

config :collector,
  root_folder: System.fetch_env!("MITRAVIAN_ROOTFOLDER"),
  collection_hour: Time.new!(
    System.fetch_env!("MITRAVIAN__COLLECTION_HOUR") |> String.to_integer(),
    System.fetch_env!("MITRAVIAN__COLLECTION_MINUTE") |> String.to_integer(),
    System.fetch_env!("MITRAVIAN__COLLECTION_SECOND") |> String.to_integer())

# config :medusa,
#   model_dir: System.fetch_env!("MITRAVIAN__MEDUSA_MODEL_DIR")

# config :prediction_bank,
#   remove_hour: Time.new!(
#     System.fetch_env!("MITRAVIAN__COLLECTION_HOUR") |> String.to_integer(),
#     System.fetch_env!("MITRAVIAN__COLLECTION_MINUTE") |> String.to_integer(),
#     System.fetch_env!("MITRAVIAN__COLLECTION_SECOND") |> String.to_integer())

