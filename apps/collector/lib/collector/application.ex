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

    opts = [strategy: :rest_for_one,
	    name: Collector.Supervisor,
	    max_restarts: 8,
	    max_seconds: 30
	   ]
    Supervisor.start_link(children, opts)
  end
end
