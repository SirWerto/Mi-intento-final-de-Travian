defmodule TDB.Repo do
  use Ecto.Repo,
    otp_app: :t_db,
    adapter: Ecto.Adapters.Postgres
end
