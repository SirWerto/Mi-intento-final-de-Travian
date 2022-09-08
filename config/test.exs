import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :front, Front.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "9zpPyYbycD3HeXqeVeUmIOBzhHdha4hOhqrFhlzJCBDI/0T4QIF4OHuLbGQMDRIg",
  server: false

config :prediction_bank,
  mnesia_dir_test: '/tmp/mnesia_test/'
