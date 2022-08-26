defmodule Medusa.GenConsumer do
  use GenStage

  require Logger

  @enforce_keys [:sup, :root_folder]
  defstruct [:sup, :root_folder, :port_pid]


  @type t :: %__MODULE__{
    sup: pid(),
    root_folder: String.t(),
    port_pid: pid() | nil
  }


  @spec start_link(sup :: pid(), root_folder :: String.t())
  :: GenServer.on_start()
  def start_link(sup, root_folder) do
    GenStage.start_link(__MODULE__, [sup, root_folder])
  end

  @impl true
  def init([sup, root_folder]) do
    state = %__MODULE__{sup: sup, root_folder: root_folder}
    send(self(), :init)
    {:consumer, state}
  end

  # @impl true
  # def handle_events(server_ids, _from, state = %__MODULE__{port_pid: pid}) do
  #   Logger.info(%{msg: "Medusa ETL start", args: {state}})
  #   server_ids
  #   |> Enum.map(fn server_id -> {server_id, medusa_etl(server_id, state)} end)
  #   |> then(fn results -> send(Medusa.GenProducer, {:medusa_etl_results, results}) end)
  #   Logger.error(%{msg: "Medusa ETL success", args: {state}})

  #   {:noreply, [], state}
  # end


  @impl true
  def handle_events([server_id], _from, state) do
    Logger.info(%{msg: "Server_id received", args: {state, server_id}})
    case Medusa.etl(state.root_folder, state.port_pid, server_id) do
      {:ok, enriched_predictions} ->
	Logger.info(%{msg: "Server_id processing ended successfuly", args: {state, server_id}})
	Satellite.send_medusa_predictions(enriched_predictions)
	GenStage.cast(Medusa.GenProducer, {:medusa_etl_result, server_id, :ok})
	{:noreply, [], state}
      {:error, reason} ->
	GenStage.cast(Medusa.GenProducer, {:medusa_etl_result, server_id, {:error, reason}})
	Logger.warning(%{msg: "Server_id processing failed", args: {state, server_id}, reason: reason})
	{:noreply, [], state}
    end
  end

  @impl true
  def handle_info(:init, state = %__MODULE__{sup: sup}) do
    port_pid = Medusa.ConsumerSup.get_model(sup)
    new_state = Map.put(state, :port_pid, port_pid)
    :ok = Medusa.GenSetUp.notify_ready(self())
    Logger.debug(%{msg: "Consumer ready", args: new_state})
    {:noreply, [], new_state}
  end
  def handle_info(_, state), do: {:noreply, [], state}



end
