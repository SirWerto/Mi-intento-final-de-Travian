import Config



config :mnesia,
  dir: System.fetch_env!("MNESIA_DIR") |> String.to_charlist()

config :collector,
  collection_hour: Time.new!(
    System.fetch_env!("COLLECTION_HOUR") |> String.to_integer(),
    System.fetch_env!("COLLECTION_MINUTE") |> String.to_integer(),
    System.fetch_env!("COLLECTION_SECOND") |> String.to_integer())

config :medusa,
  model_dir: System.fetch_env!("MEDUSA_MODEL_DIR")



