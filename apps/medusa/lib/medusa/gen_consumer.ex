defmodule Medusa.GenConsumer do
  use GenStage

  require Logger

  defstruct [:sup, :model_dir, :root_folder, port_pid: nil, setup: false, subs_tag: nil]


  @type t :: %__MODULE__{
    sup: pid(),
    model_dir: String.t(),
    root_folder: String.t(),
    port_pid: pid() | nil,
    setup: boolean(),
    subs_tag: any()
  }

  @n_snapshots 5

  @sub_options [
    to: Medusa.GenProducer,
    min_demand: 1,
    max_demand: 5]

  @spec start_link(sup :: pid(), model_dir :: String.t(), root_folder :: String.t())
  :: GenServer.on_start()
  def start_link(sup, model_dir, root_folder) do
    GenStage.start_link(__MODULE__, [sup, model_dir, root_folder])
  end

  @impl true
  def init([sup, model_dir, root_folder]) do
    state = %__MODULE__{sup: sup, model_dir: model_dir, root_folder: root_folder}
    send(self(), :init_port)
    {:consumer, state}
  end

  @impl true
  def handle_events(server_ids, _from, state = %__MODULE__{setup: true, port_pid: pid}) do
    server_ids
    |> Enum.map(fn server_id -> medusa_etl(server_id, pid) end)
    |> then(fn results -> send(Medusa.GenProducer, results) end)

    {:noreply, [], state}
  end

  @impl true
  def handle_subscribe(:producer, opts, _from, state = %__MODULE__{subs_tag: tag, setup: false, model_dir: model_dir}) do
    case {:subscription_tag, tag} in opts do
      false ->
	Logger.error(%{msg: "Unable to setup the associated port", reason: tag, args: model_dir, opts: opts})
	{:stop, :normal, state}
      true ->
	new_state = state
	|> Map.put(:setup, true)
	{:automatic, new_state}
    end
  end


  @impl true
  def handle_info(:init_port, state = %__MODULE__{sup: sup, model_dir: md, setup: false}) do
    case Medusa.ConsumerSup.start_model(sup, md) do
      {:error, reason} -> 
	Logger.error(%{msg: "Unable to setup the associated port", reason: reason, args: md})
	{:stop, :normal, state}
      {:ok, pid} ->
	{:ok, subs_tag} = GenStage.sync_subscribe(self(), @sub_options)

	new_state = state
	|> Map.put(:port_pid, pid)
	|> Map.put(:subs_tag, subs_tag)

	{:noreply, [], new_state}
    end
  end
  def handle_info(_, state), do: {:noreply, [], state}


  @spec medusa_etl(TTypes.server_id(), state :: t()) :: :ok | {:error, any()}
  def medusa_etl(server_id, state) do
    with(
      {:ok, snapshots} <- Storage.fetch_last_n_snapshots(state.root_folder, server_id, @n_snapshots),
      {_recent_date, recent} = hd(snapshots),
      processed = Medusa.Pipeline.apply(snapshots),
      {:ok, predictions} <- Medusa.GenPort.predict(processed),
      enriched_predictions = enrich_preds(predictions, processed, recent),
      :ok <- Satellite.send_medusa_predictions(enriched_predictions)
    ) do
      :ok
    else
      {:error, reason} ->
	Logger.warning(%{msg: "Medusa ETL error", reason: reason, args: state})
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
