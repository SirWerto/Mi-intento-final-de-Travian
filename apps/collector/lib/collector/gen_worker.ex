defmodule Collector.GenWorker do
  use GenServer, restart: :temporary
  require Logger

  @max_tries 3

  @delay_max 300_000
  @delay_min 5_000

  @flow_snapshot {"snapshot", ".c6bert"}
  @flow_snapshot_errors {"snapshot_errors", ".c6bert"}
  @flow_metadata {"metadata", ".bert"}

  # @spec start_link(server_id :: TTypes.server_id(), type :: :snapshot | :info) :: GenServer.on_start()
  def start_link([server_id, type]), do: GenServer.start_link(__MODULE__, [server_id, type])

  @spec stop(pid :: pid(), reason :: term(), timeout :: timeout()) :: :ok
  def stop(pid, reason \\ :normal, timeout \\ 5000), do: GenServer.stop(pid, reason, timeout)

  @impl true
  def init([url, :info]) do
    timeref =
      :erlang.send_after(:rand.uniform(@delay_max - @delay_min) + @delay_min, self(), :collect)

    {:ok, {url, :info, 0, timeref}}
  end

  def init([url, :snapshot]) do
    timeref =
      :erlang.send_after(:rand.uniform(@delay_max - @delay_min) + @delay_min, self(), :collect)

    {:ok, {url, :snapshot, 0, timeref}}
  end

  @impl true
  def handle_call(_msg, _from, state), do: {:noreply, state}

  @impl true
  def handle_cast(_msg, state), do: {:noreply, state}

  @impl true
  def handle_info(:collect, state = {server_id, type, @max_tries, _timeref}) do
    Logger.info(
      "(GenWorker)Unable to collect: #{server_id} Type: #{inspect(type)} Reason: Reached Max Tries(#{inspect(@max_tries)})"
    )

    {:stop, :normal, state}
  end

  def handle_info(:collect, state = {server_id, :snapshot, tries, _timeref}) do

    root_folder = Application.fetch_env!(:collector, :root_folder)
    case handle_collect_snapshot(root_folder,server_id) do
      :ok ->
        GenServer.cast(Collector.GenCollector, {:collected, :snapshot, server_id, self()})
        {:stop, :normal, state}

      {:error, _} ->
        timeref =
          :erlang.send_after(
            :rand.uniform(@delay_max - @delay_min) + @delay_min,
            self(),
            :collect
          )

        {:noreply, {server_id, :snapshot, tries + 1, timeref}}
    end
  end

  def handle_info(:collect, state = {server_id, :info, tries, _timeref}) do
    case handle_collect_info(server_id) do
      :ok ->
        GenServer.cast(Collector.GenCollector, {:collected, :info, server_id, self()})
        {:stop, :normal, state}

      {:error, _} ->
        timeref =
          :erlang.send_after(
            :rand.uniform(@delay_max - @delay_min) + @delay_min,
            self(),
            :collect
          )

        {:noreply, {server_id, :info, tries + 1, timeref}}
    end
  end

  def handle_info(_msg, state), do: {:noreply, state}




  @spec handle_collect_snapshot(root_folder :: binary(), server_id :: TTypes.server_id()) :: :ok | {:error, any()}
  defp handle_collect_snapshot(root_folder, server_id) do
    with(
      Logger.debug(%{msg: "Collector step 1, fetch snapshot", server_id: server_id}),
      {:step_1, {:ok, raw_snapshot}} <- {:step_1, :travianmap.get_map(server_id)},
      Logger.debug(%{msg: "Collector step 2, process snapshot", server_id: server_id}),
      {raw_rows, snapshot_errors} = :travianmap.parse_map(raw_snapshot, :no_filter)
      |> Enum.split_with(fn {atom, _} -> atom == :ok end),

      snapshot_rows = Enum.map(raw_rows, fn {:ok, row} -> Collector.SnapshotRow.apply(server_id, row) end),

      Logger.debug(%{msg: "Collector step 3, store snapshot_rows", server_id: server_id}),
      encoded_snapshot = Collector.snapshot_to_format(snapshot_rows),
      {:step_3, :ok} <- {:step_3, Storage.store(root_folder, server_id, @flow_snapshot, encoded_snapshot)},
      Logger.debug(%{msg: "Collector step 4, store snapshot_errors if there is", server_id: server_id}),
      {:step_4, :ok} <- {:step_4, store_errors(root_folder, server_id, snapshot_errors)}
    ) do
      Logger.info(%{msg: "Medusa ETL success", server_id: server_id})
      :ok
    else
      {:step_1, {:error, reason}} ->
    	Logger.info(%{msg: "Collector unable to fetch snapshot", reason: reason, server_id: server_id})
      {:step_3, {:error, reason}} ->
    	Logger.info(%{msg: "Collector unable to store snapshot", reason: reason, server_id: server_id})
      {:step_4, {:error, reason}} ->
    	Logger.info(%{msg: "Collector unable to store snapshot_errors", reason: reason, server_id: server_id})
    end
  end


  defp store_errors(_root_folder, _server_id, []), do: :ok
  defp store_errors(root_folder, server_id, snapshot_errors) do
    encoded_snapshot_errors = Collector.snapshot_errors_to_format(snapshot_errors)
    Storage.store(root_folder, server_id, @flow_snapshot_errors, encoded_snapshot_errors)
  end

  # defp handle_collect_snapshot(server_id) do
  #   case :travianmap.get_map(server_id) do
  #     {:error, reason} ->
  #       Logger.info("Unable to collect snapshot: #{server_id} Reason: #{inspect(reason)}")
  #       {:error, reason}

  #     {:ok, raw_snapshot} ->
  #       Logger.info("Snapshot successfully collected: #{server_id}")

  #       enriched_rows =
  #         for tuple <- :travianmap.parse_map(raw_snapshot, :filter),
  #             do: Collector.ProcessTravianMap.enriched_map(tuple, server_id)

  #       root_folder = Application.fetch_env!(:collector, :root_folder)

  # 	# store(root_folder, identifier, {flow_name, flow_extension}, content, date \\ Date.utc_today())
  # 	encoded_snapshot = Collector.snapshot_to_format(enriched_rows)
  #       case Storage.store(root_folder, server_id, @flow_snapshot, encoded_snapshot) do
  #         # case SnapshotEncoder.encode(enriched_rows, root_folder, now, server_id) do
  #         :ok ->
  #           Logger.info("Snapshot stored: #{server_id}")
  #           :ok

  #         {:error, reason} ->
  #           Logger.info("Unable to store snapshot: #{server_id} Reason: #{inspect(reason)}")
  #           {:error, reason}
  #       end
  #   end
  # end

  @spec handle_collect_info(server_id :: TTypes.server_id()) :: :ok | {:error, any()}
  defp handle_collect_info(server_id) do
    case :travianmap.get_info(server_id) do
      {:error, reason} ->
        Logger.info("Unable to collect metadata: #{server_id} Reason: #{inspect(reason)}")
        {:error, reason}

      {:ok, info} ->
        Logger.info("Info successfully collected: #{server_id}")
        root_folder = Application.fetch_env!(:collector, :root_folder)
        extra_info = %{"server_id" => server_id}
        enriched_info = Map.merge(info, extra_info)

	encoded_metadata = Collector.metadata_to_format(enriched_info)
        case Storage.store(root_folder, server_id, @flow_metadata, encoded_metadata) do
              :ok ->
                Logger.info("Info stored: #{server_id}")
                :ok

              {:error, reason} ->
                Logger.info("Unable to store metadata: #{server_id} Reason: #{inspect(reason)}")
                {:error, reason}
        end
    end
  end
end
