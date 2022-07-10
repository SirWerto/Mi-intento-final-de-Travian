defmodule Medusa.DynSup do
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_child(model_dir :: String.t()) :: DynamicSupervisor.on_start_child()
  def start_child(model_dir) do
    spec = %{
      id: "ConsumerSup",
      start: {Medusa.ConsumerSup, :start_link, [model_dir]},
      restart: :permanent,
      type: :supervisor
    }
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
