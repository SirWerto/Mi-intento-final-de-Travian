defmodule Medusa.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do

    brain = %{
      :id => "brain",
      :start => {Medusa.Brain, :start_link, []},
      :restart => :permanent,
      :shutdown => 5_000,
      :type => :worker
    }

    children = [
      brain
    ]

    opts = [strategy: :one_for_all, name: Medusa.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def stop(_state) do
    :ok
  end
end
