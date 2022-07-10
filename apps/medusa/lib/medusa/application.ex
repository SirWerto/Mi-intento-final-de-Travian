defmodule Medusa.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do

    # model_dir = Application.fetch_env!(:medusa, :model_dir)

    model_dir = Application.fetch_env!(:medusa, :model_dir)
    root_folder = Application.fetch_env!(:medusa, :root_folder)
    n_consumers = Application.fetch_env!(:medusa, :n_consumers)

    producer = %{
      :id => "producer",
      :start => {Medusa.GenProducer, :start_link, [model_dir, root_folder, n_consumers]},
      :restart => :permanent,
      :shutdown => 5_000,
      :type => :worker
    }


    dyn_sup = %{
      :id => "dynsup",
      :start => {Medusa.DynSup, :start_link, []},
      :restart => :permanent,
      :shutdown => 5_000,
      :type => :supervisor
    }

     children = [producer, dyn_sup]
    

    opts = [strategy: :rest_for_one, name: Medusa.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def stop(_state) do
    :ok
  end
end
