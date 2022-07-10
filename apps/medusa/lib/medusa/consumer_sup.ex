defmodule Medusa.ConsumerSup do
  use Supervisor

  @spec start_link(model_dir :: String.t()) :: Supervisor.on_start()
  def start_link(model_dir) do
    Supervisor.start_link(__MODULE__, model_dir)
  end

  @impl true
  def init(model_dir) do
    consumer = %{
      :id => "consumer",
      :start => {Medusa.Consumer, :start_link, [self(), model_dir]},
      :restart => :permanent,
      :shutdown => 5_000,
      :type => :worker
    }
    children = [consumer]
    Supervisor.init(children, strategy: :one_for_all)
  end

  @spec start_model(sup :: pid(), model_dir :: String.t())
  :: Supervisor.on_start_child()
  def start_model(sup, model_dir) do
    model_spec = %{
      id: "python model",
      start: {Medusa.GenPort, :start_link, [model_dir]},
      restart: :temporary,
      shutdown: 5_000,
      type: :worker
    }
    Supervisor.start_child(sup, model_spec)
  end
end
