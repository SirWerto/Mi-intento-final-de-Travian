defmodule Collector.GenWorker.Snapshot do
  use GenServer
  require Logger

  @max_tries 3

  @spec start_link(server_id :: TTypes.server_id(), max_tries :: pos_integer()) ::
          GenServer.on_start()
  def start_link(server_id, max_tries \\ @max_tries),
    do: GenServer.start_link(__MODULE__, [server_id, max_tries])

  @impl true
  def init([server_id, max_tries]) do
    delay_max = Application.get_env(:collector, :delay_max, 300_000)
    delay_min = Application.get_env(:collector, :delay_min, 5_000)
    {:ok, {server_id, max_tries, 0}, compute_sleep(delay_min, delay_max)}
  end

  @impl true
  def handle_info(:timeout, state = {server_id, max_tries, max_tries}) do
    Logger.info(%{
      msg: "Unable to collect snapshot",
      type_collection: :snapshot,
      reason: :max_tries,
      server_id: server_id
    })

    {:stop, :normal, state}
  end

  def handle_info(:timeout, state = {server_id, max_tries, n}) when max_tries > n do
    root_folder = Application.fetch_env!(:collector, :root_folder)

    case etl(root_folder, server_id) do
      :ok ->
        {:stop, :normal, state}

      {:error, _} ->
        delay_max = Application.get_env(:collector, :delay_max, 300_000)
        delay_min = Application.get_env(:collector, :delay_min, 5_000)
        {:noreply, {server_id, max_tries, n + 1}, compute_sleep(delay_min, delay_max)}
    end
  end

  @spec etl(root_folder :: binary(), server_id :: TTypes.server_id()) :: :ok | {:error, any()}
  def etl(root_folder, server_id) do
    today = Date.utc_today()

    with(
      Logger.debug(%{
        msg: "Collector step 1, fetch snapshot",
        type_collection: :snapshot,
        server_id: server_id
      }),
      {:step_1, {:ok, raw_snapshot}} <- {:step_1, :travianmap.get_map(server_id)},
      Logger.debug(%{
        msg: "Collector step 2, store raw_snapshot",
        type_collection: :snapshot,
        server_id: server_id
      }),
      {:step_2, :ok} <-
        {:step_2,
         Storage.store(
           root_folder,
           server_id,
           Collector.raw_snapshot_options(),
           Collector.raw_snapshot_to_format(raw_snapshot),
           today
         )},
      Logger.debug(%{
        msg: "Collector step 3, process snapshot",
        type_collection: :snapshot,
        server_id: server_id
      }),
      {raw_rows, snapshot_errors} =
        :travianmap.parse_map(raw_snapshot, :no_filter)
        |> Enum.split_with(fn {atom, _} -> atom == :ok end),
      snapshot_rows =
        Enum.map(raw_rows, fn {:ok, row} -> Collector.SnapshotRow.apply(server_id, row) end),
      Logger.debug(%{
        msg: "Collector step 4, store snapshot_rows",
        type_collection: :snapshot,
        server_id: server_id
      }),
      encoded_snapshot = Collector.snapshot_to_format(snapshot_rows),
      {:step_4, :ok} <-
        {:step_4,
         Storage.store(
           root_folder,
           server_id,
           Collector.snapshot_options(),
           encoded_snapshot,
           today
         )},
      GenServer.cast(Collector.GenCollector, {:snapshot_collected, server_id, self()}),
      Logger.debug(%{
        msg: "Collector step 5, store snapshot_errors if there is",
        type_collection: :snapshot,
        server_id: server_id
      }),
      {:step_5, :ok} <- {:step_5, store_errors(root_folder, server_id, snapshot_errors, today)},
      Logger.debug(%{
        msg: "Collector step 6, compute players_snapshot",
        type_collection: :snapshot,
        server_id: server_id
      }),
      players_snapshot = Collector.PlayersSnapshot.group(snapshot_rows),
      Logger.debug(%{
        msg: "Collector step 7, store players_snapshot",
        type_collection: :snapshot,
        server_id: server_id
      }),
      encoded_players_snapshot = Collector.players_snapshot_to_format(players_snapshot),
      {:step_7, :ok} <-
        {:step_7,
         Storage.store(
           root_folder,
           server_id,
           Collector.players_snapshot_options(),
           encoded_players_snapshot,
           today
         )},
      GenServer.cast(Collector.GenCollector, {:players_snapshot_computed, server_id, self()}),

      {:step_8, :ok} <- {:step_8, store_server_metadata_if_needed(root_folder, server_id)},
      GenServer.cast(Collector.GenCollector, {:server_metadata_computed, server_id, self()})
    ) do
      Logger.info(%{
        msg: "Collector snapshot success",
        type_collection: :snapshot,
        server_id: server_id
      })

      :ok
    else
      {:step_1, {:error, reason}} ->
        Logger.info(%{
          msg: "Collector unable to fetch snapshot",
          reason: reason,
          type_collection: :snapshot,
          server_id: server_id
        })

        {:error, reason}

      {:step_2, {:error, reason}} ->
        Logger.warning(%{
          msg: "Collector unable to store raw_snapshot",
          reason: reason,
          type_collection: :snapshot,
          server_id: server_id
        })

        {:error, reason}

      {:step_4, {:error, reason}} ->
        Logger.warning(%{
          msg: "Collector unable to store snapshot",
          reason: reason,
          type_collection: :snapshot,
          server_id: server_id
        })

        {:error, reason}

      {:step_5, {:error, reason}} ->
        Logger.info(%{
          msg: "Collector unable to store snapshot_errors",
          reason: reason,
          type_collection: :snapshot,
          server_id: server_id
        })

        {:error, reason}

      {:step_7, {:error, reason}} ->
        Logger.info(%{
          msg: "Collector unable to store players_snapshot",
          reason: reason,
          type_collection: :snapshot,
          server_id: server_id
        })

        {:error, reason}

      {:step_8, {:error, reason}} ->
        Logger.info(%{
          msg: "Collector unable to store server_metadata",
          reason: reason,
          type_collection: :snapshot_server_metadata,
          server_id: server_id
        })

        {:error, reason}
    end
  end

  @spec store_errors(
          root_folder :: binary(),
          server_id :: TTypes.server_id(),
          snapshot_errors :: [any()],
          date :: Date.t()
        ) :: :ok | {:error, any()}
  defp store_errors(_root_folder, _server_id, [], _date), do: :ok

  defp store_errors(root_folder, server_id, snapshot_errors, date) do
    encoded_snapshot_errors =
      snapshot_errors
      |> Enum.map(fn {:error, value} -> value end)
      |> Collector.snapshot_errors_to_format()

    case Storage.store(
           root_folder,
           server_id,
           Collector.snapshot_errors_options(),
           encoded_snapshot_errors,
           date
         ) do
      :ok ->
        GenServer.cast(Collector.GenCollector, {:snapshot_errors_collected, server_id, self()})

      {:error, reason} ->
        GenServer.cast(Collector.GenCollector, {:snapshot_errors_no_collected, server_id, self()})
        {:error, reason}
    end
  end

  @spec compute_sleep(min :: pos_integer(), max :: pos_integer()) :: pos_integer()
  defp compute_sleep(min, max) when max >= min do
    :rand.uniform(max - min) + min
  end


  defp store_server_metadata_if_needed(root_folder, server_id) do
    case Storage.exist?(root_folder, server_id, Collector.server_metadata_options(), :unique) do
      true -> :ok
      false -> 
    Logger.debug(%{
          msg: "Collector step 8, store server_metadata",
          type_collection: :snapshot_server_metadata,
          server_id: server_id
		 })
      encoded_server_metadata = %Collector.ServerMetadata{
	estimated_starting_date: Date.utc_today(),
	url: server_id,
	server_id: server_id} 
	|> Collector.server_metadata_to_format()

         Storage.store(
           root_folder,
           server_id,
           Collector.server_metadata_options(),
           encoded_server_metadata,
           :unique)
    end
  end
end
