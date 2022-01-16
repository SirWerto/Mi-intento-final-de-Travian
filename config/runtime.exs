import Config



config :logger,
  :console,
  level: System.get_env("MITRAVIAN__LOGGER_LEVEL", "info") |> String.to_atom(),
  format: "$node $date $time [$level] ($metadata) $message\n",
  metadata: [:mfa]




config :mnesia,
  dir: System.fetch_env!("MITRAVIAN__MNESIA_DIR") |> String.to_charlist()

config :t_db, TDB.Repo,
  database: System.fetch_env!("MITRAVIAN__TDB_DATABASE"),
  username: System.fetch_env!("MITRAVIAN__TDB_USERNAME"),
  password: System.fetch_env!("MITRAVIAN__TDB_PASSWORD"),
  hostname: System.fetch_env!("MITRAVIAN__TDB_HOSTNAME")


config :collector,
  collection_hour: Time.new!(
    System.fetch_env!("MITRAVIAN__COLLECTION_HOUR") |> String.to_integer(),
    System.fetch_env!("MITRAVIAN__COLLECTION_MINUTE") |> String.to_integer(),
    System.fetch_env!("MITRAVIAN__COLLECTION_SECOND") |> String.to_integer())

config :medusa,
  model_dir: System.fetch_env!("MITRAVIAN__MEDUSA_MODEL_DIR")


config :prediction_bank,
  remove_hour: Time.new!(
    System.fetch_env!("MITRAVIAN__COLLECTION_HOUR") |> String.to_integer(),
    System.fetch_env!("MITRAVIAN__COLLECTION_MINUTE") |> String.to_integer(),
    System.fetch_env!("MITRAVIAN__COLLECTION_SECOND") |> String.to_integer())

