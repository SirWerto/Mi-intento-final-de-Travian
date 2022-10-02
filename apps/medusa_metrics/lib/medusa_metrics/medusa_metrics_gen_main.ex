defmodule MedusaMetrics.GenMain do
  use GenServer

  require Logger


  defstruct [medusa_status: :inactive, status: :inactive, process: [], failed: [], metrics: nil, medusa_ref: nil]


  @type t :: %__MODULE__{
    medusa_status: :active | :inactive,
    status: :active | :inactive,
    medusa_ref: nil | reference(),
    process: [TTypes.server_id()],
    metrics: nil | MedusaMetrics.Metrics.t(),
    failed: list(MedusaMetrics.Failed.t())
  }

  @spec start_link([]) :: GenServer.on_start()
  def start_link([]), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl true
  def init([]), do: {:ok, [], {:continue, :init}}

  @impl true
  def handle_continue(:init, []) do
    ref = Medusa.subscribe()
    {:noreply, %__MODULE__{medusa_ref: ref}}
  end
  def handle_continue(:eval_finish, state) when state.medusa_status == :inactive and state.status == :active and state.process == [] do
      new_state = Map.put(state, :status, :inactive)
      store(new_state.failed, new_state.metrics)
      Logger.info(%{msg: "MedusaMetrics.GenMain inactive"})
      {:noreply, new_state}
  end
  def handle_continue(:eval_finish, state), do: {:noreply, state}

  @impl true
  def handle_call(_msg, _from, state), do: {:noreply, state}

  @impl true
  def handle_cast({:medusa_metrics_et_result, server_id, {:error, _reason}}, state) do
    new_state = Map.put(state, :process, state.process -- [server_id])
    {:noreply, new_state, {:continue, :eval_finish}}
  end
  def handle_cast({:medusa_metrics_et_result, server_id, {failed, metrics}}, state) do
    new_state = state
    |> Map.put(:metrics, MedusaMetrics.Metrics.merge(state.metrics, metrics))
    |> Map.put(:failed, failed ++ state.failed)
    |> Map.put(:process, state.process -- [server_id])
    {:noreply, new_state, {:continue, :eval_finish}}
  end
  def handle_cast(_msg, state), do: {:noreply, state}

  @impl true
  def handle_info({:medusa_event, :prediction_started}, state) do
    today = Date.utc_today()
    yesterday = Date.add(today, -1)
    new_state = %__MODULE__{
      medusa_status: :active,
      medusa_ref: state.medusa_ref,
      status: :active,
      process: [],
      failed: [],
      metrics: %MedusaMetrics.Metrics{
	target_date: today,
	old_date: yesterday,
	models: %{},
	total_players: 0,
	failed_players: 0,
	square: %MedusaMetrics.Square{t_p: 0, t_n: 0, f_p: 0, f_n: 0}
      },
    }
    Logger.info(%{msg: "MedusaMetrics.GenMain active"})
    {:noreply, new_state}
  end
  def handle_info({:medusa_event, :prediction_finished}, state) do
    new_state = Map.put(state, :medusa_status, :inactive)
    {:noreply, new_state, {:continue, :eval_finish}}
  end

  def handle_info({:medusa_event, {:prediction_done, server_id}}, state) do
    Logger.debug(%{msg: "MedusaMetrics.GenMain prediction received", server_id: server_id})
    today = Date.utc_today()
    yesterday = Date.add(today, -1)
    root_folder = Application.fetch_env!(:medusa_metrics, :root_folder)
    case MedusaMetrics.DynSup.start_child(root_folder, server_id, today, yesterday) do
      {:ok, _pid} ->
	new_state = Map.put(state, :process, [server_id | state.process])
	{:noreply, new_state}
      {:ok, _pid, _info} ->
	new_state = Map.put(state, :process, [server_id | state.process])
	{:noreply, new_state}
      :ignore -> {:noreply, state}
      {:error, reason} ->
	Logger.warning(%{msg: "MedusaMetrics.GenMain unable to start child", server_id: server_id, reason: reason})
	{:noreply, state}
    end
  end
  def handle_info(_msg, state), do: {:noreply, state}


  defp store(failed, metrics) do
    with(
      {:step_1, {:ok, root_folder}} <- {:step_1, Application.fetch_env(:medusa_metrics, :root_folder)},
      encoded_failed = MedusaMetrics.failed_to_format(failed),
      encoded_metrics = MedusaMetrics.metrics_to_format(metrics),
      {:step_2, :ok} <- {:step_2, Storage.store(root_folder, :global, MedusaMetrics.metrics_options(), encoded_metrics)},
      Logger.debug(%{msg: "MedusaMetrics metrics stored"}),
      {:step_3, :ok} <- {:step_3, Storage.store(root_folder, :global, MedusaMetrics.failed_options(), encoded_failed)},
      Logger.debug(%{msg: "MedusaMetrics failed stored"})
    ) do
      :ok
    else
      {:step_1, :error} ->
	Logger.warning(%{msg: "MedusaMetrics ETL error", step: 1, reason: "unable to fetch root_folder"})
	{:error, "unable to fetch root_folder"}
      {:step_2, {:error, reason}} ->
	Logger.warning(%{msg: "MedusaMetrics ETL error", step: 2, reason: {"unable to store the metrics", reason}})
	{:error, reason}
      {:step_3, {:error, reason}} ->
	Logger.warning(%{msg: "MedusaMetrics ETL error", step: 3, reason: {"unable to store the failed", reason}})
	{:error, reason}
    end
  end
end
