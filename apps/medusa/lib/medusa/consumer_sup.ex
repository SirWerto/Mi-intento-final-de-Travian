defmodule Medusa.ConsumerSup do
  use Supervisor

  @spec start_link(model_dir :: String.t(), root_folder :: String.t()) :: Supervisor.on_start()
  def start_link(model_dir, root_folder) do
    Supervisor.start_link(__MODULE__, [model_dir, root_folder])
  end

  @impl true
  def init([model_dir, root_folder]) do

    consumer = %{
      :id => "consumer",
      :start => {Medusa.GenConsumer, :start_link, [self(), root_folder]},
      :restart => :temporary,
      :shutdown => 5_000,
      :significant => true,
      :type => :worker
    }

    model = %{
      id: "python model",
      start: {Medusa.GenPort, :start_link, [model_dir]},
      restart: :temporary,
      shutdown: 5_000,
      type: :worker
    }


    children = [model, consumer]
    sup_flags = %{
      strategy: :one_for_all,
      auto_shutdown: :any_significant,
    }
    {:ok, {sup_flags, children}}
    # Supervisor.init(children, strategy: :one_for_all)
  end

  @spec get_model(sup :: pid()) :: pid()
  def get_model(sup) do
    [{_id, model_pid, _type, _modules}] =
      Supervisor.which_children(sup)
      |> Enum.filter(fn {id, _child, _type, _modules} -> id == "python model" end)
    model_pid
  end
end
