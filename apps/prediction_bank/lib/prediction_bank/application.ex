defmodule PredictionBank.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: PredictionBank.Worker.start_link(arg)
      # {PredictionBank.Worker, arg}
    ]

    tables = [:bank_players]

    :mnesia.wait_for_tables(tables, 5000)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PredictionBank.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
