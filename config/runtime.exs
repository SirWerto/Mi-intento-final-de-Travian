import Config



config :mnesia,
  dir: '/home/jorge/tmp/mnesia/'

config :collector,
  collection_hour: ~T[09:00:00]

config :medusa,
  model_dir: System.fetch_env!("MEDUSA_MODEL_DIR")



