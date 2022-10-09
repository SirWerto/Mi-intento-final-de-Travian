defmodule Satellite.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do

    gen_cleaner = %{
      :id => "gen_cleaner",
      :start => {Satellite.MedusaTable.GenCleaner, :start_link, []},
      :restart => :permanent,
      :shutdown => 5_000,
      :type => :worker
    }

    children = [gen_cleaner]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Satellite.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
