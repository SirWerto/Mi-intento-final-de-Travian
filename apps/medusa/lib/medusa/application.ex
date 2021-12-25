defmodule Medusa.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do

    model_dir = Application.fetch_env!(:medusa, :model_dir)

    producer = %{
      :id => "producer",
      :start => {Medusa.Producer, :start_link, []},
      :restart => :permanent,
      :shutdown => 5_000,
      :type => :worker
    }

    consumers = for i <- [1], do: %{
      :id => "consumer_" <> Integer.to_string(i),
      :start => {Medusa.Consumer, :start_link, [model_dir]},
      :restart => :permanent,
      :shutdown => 5_000,
      :type => :worker
    }

    IO.inspect(consumers)

    children = [producer | consumers]
    

    opts = [strategy: :one_for_all, name: Medusa.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def stop(_state) do
    :ok
  end
end
