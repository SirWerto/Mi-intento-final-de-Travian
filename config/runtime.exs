import Config

config :collector,
  ctime: ~T[09:00:00]

config :medusa,
  model_dir: System.fetch_env!("MEDUSA_MODEL_DIR")

