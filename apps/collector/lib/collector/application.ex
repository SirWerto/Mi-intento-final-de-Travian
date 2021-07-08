defmodule Collector.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    plubio = %{
      :id => "plubio",
      :start => {Collector.Plubio, :start_link, []},
      :restart => :permanent,
      :shutdown => 5_000,
      :type => :worker
    }
    children = [
      {Finch, name: TFinch},
      plubio
    ]

    opts = [strategy: :rest_for_one, name: Collector.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
