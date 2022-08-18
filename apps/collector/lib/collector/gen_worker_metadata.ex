defmodule Collector.GenWorker.Metadata do
  use GenServer
  require Logger

  @flow_metadata {"metadata", ".bert"}

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
      msg: "Unable to collect metadata",
      type_collection: :metadata,
      reason: :max_tries,
      server_id: server_id
    })

    {:stop, :normal, state}
  end

  def handle_info(:timeout, state = {server_id, max_tries, n}) when max_tries > n do
    root_folder = Application.fetch_env!(:collector, :root_folder)

    case etl(root_folder, server_id) do
      :ok ->
        GenServer.cast(Collector.GenCollector, {:collected, :metadata, server_id, self()})
        {:stop, :normal, state}

      {:error, _} ->
        delay_max = Application.get_env(:collector, :delay_max, 300_000)
        delay_min = Application.get_env(:collector, :delay_min, 5_000)
        {:noreply, {server_id, max_tries, n + 1}, compute_sleep(delay_max, delay_min)}
    end
  end

  @spec etl(root_folder :: binary(), server_id :: TTypes.server_id()) :: :ok | {:error, any()}
  def etl(root_folder, server_id) do
    with(
      Logger.debug(%{
        msg: "Collector step 1, fetch metadata",
        type_collection: :metadata,
        server_id: server_id
      }),
      {:step_1, {:ok, metadata}} <- {:step_1, :travianmap.get_info(server_id)},
      metadata = Map.put(metadata, "server_id", server_id),
      Logger.debug(%{
        msg: "Collector step 2, store metadata",
        type_collection: :metadata,
        server_id: server_id
      }),
      encoded_metadata = Collector.metadata_to_format(metadata),
      {:step_2, :ok} <-
        {:step_2, Storage.store(root_folder, server_id, @flow_metadata, encoded_metadata)}
    ) do
      Logger.info(%{
        msg: "Collector metadata success",
        type_collection: :metadata,
        server_id: server_id
      })

      :ok
    else
      {:step_1, {:error, reason}} ->
        Logger.info(%{
          msg: "Collector unable to fetch metadata",
          reason: reason,
          type_collection: :metadata,
          server_id: server_id
        })
	{:error, reason}

      {:step_2, {:error, reason}} ->
        Logger.warning(%{
          msg: "Collector unable to store metadata",
          reason: reason,
          type_collection: :metadata,
          server_id: server_id
        })
	{:error, reason}
    end
  end

  @spec compute_sleep(min :: pos_integer(), max :: pos_integer()) :: pos_integer()
  defp compute_sleep(min, max) when max >= min do
    :rand.uniform(max - min) + min
  end
end
