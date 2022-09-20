defmodule MedusaMetrics.DynSup do
  use DynamicSupervisor

  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end


  @spec start_child(root_folder :: binary(), server_id :: TTypes.server_id(), target_date :: Date.t(), old_date :: Date.t()) :: DynamicSupervisor.on_start_child()
  def start_child(root_folder, server_id, target_date, old_date) do
    specs = %{
      id: "MedusaMetrics.GenWorker",
      start: {MedusaMetrics.GenWorker, :start_link, [root_folder, server_id, target_date, old_date]},
      restart: :temporary,
      type: :worker,
      modules: [MedusaMetrics.GenWorker]
    }
    DynamicSupervisor.start_child(__MODULE__, specs)
  end
end
