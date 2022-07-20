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

  @n_snapshots 5

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

  @impl true
  def handle_events(server_ids, _from, state = %__MODULE__{port_pid: pid}) do
    server_ids
    |> Enum.map(fn server_id -> {server_id, medusa_etl(server_id, pid)} end)
    |> then(fn results -> send(Medusa.GenProducer, {:medusa_etl_results, results}) end)

    {:noreply, [], state}
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


  @spec medusa_etl(TTypes.server_id(), state :: t()) :: :ok | {:error, any()}
  def medusa_etl(server_id, state) do
    with(
      {:ok, snapshots} <- Storage.fetch_last_n_snapshots(state.root_folder, server_id, @n_snapshots),
      {_recent_date, recent} = hd(snapshots),
      processed = Medusa.Pipeline.apply(snapshots),
      {:ok, predictions} <- Medusa.GenPort.predict(state.port_pid, processed),
      enriched_predictions = enrich_preds(predictions, processed, recent),
      :ok <- Satellite.send_medusa_predictions(enriched_predictions)
    ) do
      Logger.info(%{msg: "Medusa ETL success", args: {server_id, state}})
      :ok
    else
      {:error, reason} ->
	Logger.warning(%{msg: "Medusa ETL error", reason: reason, args: {server_id, state}})
        {:error, reason}
    end
  end



  @spec enrich_preds(pridictions :: [Medusa.Port.t()], processed :: [Medusa.Pipeline.Step2.t()], recent :: [TTypes.enriched_row()]) :: [map()]
  defp enrich_preds(predictions, processed, recent) do
    recent_filtered = Enum.sort(recent, &(&1.player_id >= &2.player_id)) |> Enum.dedup_by(&(&1.player_id))
    for pred <- predictions, proc <- processed, raw <- recent_filtered, pred.player_id == proc.fe_struct.player_id == raw.player_id, do: enrich_map(pred, proc, raw)
  end

  @spec enrich_map(pred :: Medusa.Port.t(), proc :: Medusa.Pipeline.Step2.t(), raw :: TTypes.enriched_row()) :: map()
  defp enrich_map(pred, proc, raw) do
    %{
      player_id: pred.player_id,
      player_name: raw.player_name,
      player_url: pred.player_id,
      alliance_id: raw.alliance_id,
      alliance_name: raw.alliance_name,
      alliance_url: raw.alliance_name,
      inactive_in_future: pred.inactive_in_future,
      inactive_in_current: proc.fe_struct.inactive_in_current,
      total_population: proc.fe_struct.total_population,
      n_villages: proc.fe_struct.n_villages
    }
  end

end
