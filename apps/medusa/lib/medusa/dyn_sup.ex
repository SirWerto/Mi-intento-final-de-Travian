defmodule Medusa.DynSup do
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_consumer_sup(model_dir :: String.t(), root_folder :: String.t()) :: DynamicSupervisor.on_start_child()
  def start_consumer_sup(model_dir, root_folder) do
    spec = %{
      id: "ConsumerSup",
      start: {Medusa.ConsumerSup, :start_link, [model_dir, root_folder]},
      restart: :temporary,
      type: :supervisor
    }
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
