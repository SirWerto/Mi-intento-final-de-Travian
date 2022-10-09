defmodule Satellite.MedusaTable.GenCleaner do
  use GenServer
  require Logger


  @spec start_link() :: GenServer.on_start()
  def start_link(), do: GenServer.start_link(__MODULE__, [])


  @impl true
  def init([]) do
    {:ok, {}, {:continue, []}}
  end

  @impl true
  def handle_continue(_continue, {}) do
    case Collector.subscribe() do
      {:ok, ref} ->
	collector = Process.whereis(Collector.GenCollector)
	Logger.info(%{msg: "Subscribed to Collector"})
	{:noreply, {collector, ref}}
      {:error, reason} ->
	Logger.warning(%{msg: "Unable to subscribe to Collector", reason: reason})
	{:stop, :normal}
    end
  end


  @impl true
  def handle_call(_msg, _from, state), do: {:noreply, state}

  @impl true
  def handle_cast(_msg, state), do: {:noreply, state}


  @impl true
  def handle_info({:collector_event, :collection_started}, state) do
    Logger.debug(%{msg: "Collection event received, cleaning MedusaTable"})
    Satellite.MedusaTable.clear_table()
    {:noreply, state}
  end
  def handle_info({:DOWN, ref, :process, pid, _}, {pid, ref}) do
    Logger.info(%{msg: "Collector down, stopping"})
    {:stop, :normal}
  end
  def handle_info(_msg, state), do: {:noreply, state}

end
