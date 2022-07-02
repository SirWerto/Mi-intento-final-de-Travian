defmodule Medusa.GenConsumer do
  use GenStage

  defstruct [:sup, :model_dir, :root_folder, port_pid: nil, setup: false, subs_tag: nil]

  @n_snapshots 5

  @sub_options [
    to: Medusa.GenProducer,
    min_demand: 1,
    max_demand: 5]

  @spec start_link(sup :: pid(), model_dir :: String.t(), root_folder :: String.t())
  :: GenServer.on_start()
  def start_link(sup, model_dir, root_folder) do
    GenStage.start_link(__MODULE__, [sup, model_dir])
  end

  @impl true
  def init(sup, model_dir, root_folder) do
    state = %__MODULE__{sup: sup, model_dir: model_dir, root_folder: root_folder}
    send(self(), :init_port)
    {:consumer, state}
  end

  @impl true
  def handle_events(server_ids, _from, state = %__MODULE__{setup: true, port_pid: pid}) do
    server_ids
    |> Enum.map(server_ids, fn server_id -> medusa_etl(server_id, pid) end)
    |> then(fn results -> send(Medusa.GenProducer, results))

    {:noreply, [], state}
  end

  @impl true
  def handle_subscribe(:producer, opts, _from, state = %__MODULE__{subs_tag: tag, setup: false}) do
    case {:subscription_tag, tag} in opts do
      false ->
	Logger.error(%{msg: "Unable to setup the associated port", reason: reason, args: model_dir, opts: opts})
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
	Logger.error(%{msg: "Unable to setup the associated port", reason: reason, args: model_dir})
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


  @spec medusa_etl(TTypes.server_id()) :: :ok | {:error, any()}
  def medusa_etl(server_id, state) do
    with
    {:ok, snapshots} <- Storage.fetch_last_n_snapshots(state.root_folder, server_id, @n_snapshots),
    processed = Medusa.Pipeline.apply(snapshots)
    {:ok, predictions} <- Medusa.GenPort.predict(processed)
    enriched_predictions = enrich_preds(predictions, processed)
    :ok <- Satellite.send_medusa_predictions(enriched_predictions) do
      :ok
    else
      {:error, reason} ->
	Logger.warning(%{msg: "Medusa ETL error", reason: reason, args: state})
        {:error, reason}
    end

  end
end
