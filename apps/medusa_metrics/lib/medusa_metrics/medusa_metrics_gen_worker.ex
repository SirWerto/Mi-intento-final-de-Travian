defmodule MedusaMetrics.GenWorker do
  use GenServer

  require Logger



  @spec start_link(root_folder :: binary(), server_id :: TTypes.server_id(), target_date :: Date.t(), old_date :: Date.t()) :: GenServer.on_start()
  def start_link(root_folder, server_id, target_date, old_date), do: GenServer.start_link(__MODULE__, [root_folder, server_id, target_date, old_date])

  @impl true
  def init([root_folder, server_id, target_date, old_date]) do
    send(self(), :start)
    {:ok, {root_folder, server_id, target_date, old_date}}
  end


  @impl true
  def handle_call(_msg, _from, state), do: {:noreply, state}

  @impl true
  def handle_cast(_msg, state), do: {:noreply, state}

  @impl true
  def handle_info(:start, state = {root_folder, server_id, target_date, old_date}) do
    case MedusaMetrics.et(root_folder, server_id, target_date, old_date) do
      {:ok, {metrics, failed}} ->
	Logger.info(%{msg: "MedusaMetrics.GenWorker ET metrics computed", server_id: server_id})
	GenServer.cast(MedusaMetrics.GenMain, {:medusa_metrics_et_result, server_id, {failed, metrics}})
	{:stop, :normal, state}
      {:error, reason} -> 
	Logger.warning(%{msg: "MedusaMetrics.GenWorker ET error, unable to compute metrics", server_id: server_id, reason: reason})
	GenServer.cast(MedusaMetrics.GenMain, {:medusa_metrics_et_result, server_id, {:error, reason}})
    {:stop, :normal, state}
    end
  end
  def handle_info(_msg, state), do: {:noreply, state}

end
