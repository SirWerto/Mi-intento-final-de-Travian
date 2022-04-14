defmodule Collector.GenWorker do
  use GenServer, restart: :temporary
  require Logger


  @max_tries 10


  @delay_max 300_000
  @delay_min 5_000

  # @spec start_link(server_id :: TTypes.server_id(), type :: :snapshot | :info) :: GenServer.on_start()
  def start_link([server_id, :snapshot]), do: GenServer.start_link(__MODULE__, [server_id, :snapshot])
  def start_link([server_id, :info]), do: GenServer.start_link(__MODULE__, [server_id, :info, nil])

  
  @spec stop(pid :: pid(), reason :: term(), timeout :: timeout()) :: :ok
  def stop(pid, reason \\ :normal, timeout \\ 5000), do: GenServer.stop(pid, reason, timeout)


  @impl true
  def init([url, :info, init_date]) do
    timeref = :erlang.send_after(:rand.uniform(@delay_max - @delay_min) + @delay_min, self(), :collect)
    {:ok, {url, :info, init_date, 0, timeref}}
  end

  def init([url, :snapshot]) do
    timeref = :erlang.send_after(:rand.uniform(@delay_max - @delay_min) + @delay_min, self(), :collect)
    {:ok, {url, :snapshot, 0, timeref}}
  end




  @impl true
  def handle_call(_msg, _from, state), do: {:noreply, state}

  @impl true
  def handle_cast(_msg, state), do: {:noreply, state}


  @impl true
  def handle_info(:collect, state = {server_id, type, _init_date, @max_tries, _timeref}) do
    Logger.info("(GenWorker)Unable to collect: #{server_id} Type: #{inspect(type)} Reason: Reached Max Tries(#{inspect(@max_tries)})")
    {:stop, :normal, state}
  end
  def handle_info(:collect, state = {server_id, :snapshot, tries, _timeref}) do
    case handle_collect_snapshot(server_id) do
      :ok -> {:stop, :normal, state}
      {:error, _} -> 
	timeref = :erlang.send_after(:rand.uniform(@delay_max - @delay_min) + @delay_min, self(), :collect)
	{:noreply, {server_id, :snapshot, tries+1, timeref}}
    end
  end
  def handle_info(:collect, state = {server_id, :info, init_date, tries, _timeref}) do
    case handle_collect_info(server_id, init_date) do
      :ok -> {:stop, :normal, state}
      {:error, _} -> 
	timeref = :erlang.send_after(:rand.uniform(@delay_max - @delay_min) + @delay_min, self(), :collect)
	{:noreply, {server_id, :info, init_date, tries+1, timeref}}
    end
  end

  def handle_info(_msg, state), do: {:noreply, state}



  @spec handle_collect_snapshot(server_id :: TTypes.server_id()) :: :ok | {:error, any()}
  def handle_collect_snapshot(server_id) do
    case :travianmap.get_map(server_id) do
      {:error, reason} ->
	Logger.info("Unable to collect snapshot: #{server_id} Reason: #{inspect(reason)}")
	{:error, reason}
      {:ok, raw_snapshot} ->
	Logger.info("Snapshot successfully collected: #{server_id}")
	enriched_rows = for tuple <- :travianmap.parse_map(raw_snapshot, :filter), do: Collector.ProcessTravianMap.enriched_map(tuple, server_id)
	root_folder = Application.fetch_env!(:collector, :root_folder)
	now = DateTime.now!("Etc/UTC") |> DateTime.to_date()
	case Storage.store_snapshot(root_folder, server_id, now, enriched_rows) do
	# case SnapshotEncoder.encode(enriched_rows, root_folder, now, server_id) do
	  :ok ->
	    Logger.info("Snapshot stored: #{server_id}")
	    :ok
	  {:error, reason} ->
	    Logger.info("Unable to store snapshot: #{server_id} Reason: #{inspect(reason)}")
	    {:error, reason}
	end
    end
  end


  @spec handle_collect_info(server_id :: TTypes.server_id(), init_date :: Date.t() | nil) :: :ok | {:error, any()}
  def handle_collect_info(server_id, init_date) do
    case :travianmap.get_info(server_id) do
      {:error, reason} ->
	Logger.info("Unable to collect info: #{server_id} Reason: #{inspect(reason)}")
	{:error, reason}
      {:ok, info} ->
	Logger.info("Info successfully collected: #{server_id}")
	root_folder = Application.fetch_env!(:collector, :root_folder)
	now = DateTime.now!("Etc/UTC") |> DateTime.to_date()
	extra_info = %{"server_id" => server_id, "init_date" => init_date}
	enriched_info = Map.merge(info, extra_info)
	case Storage.fetch_last_info(root_folder, server_id) do
	# case last_server_info(root_folder, server_id) do
	  {:error, reason} ->
	    Logger.info("Unable to store info: #{server_id} Reason: #{inspect(reason)}")
	    {:error, reason}
	  {:ok, :no_files} ->
	    case Storage.store_info(root_folder, server_id, now, enriched_info) do
	    # case SnapshotEncoder.encode_info(enriched_info, root_folder, now, server_id) do
	      :ok ->
		Logger.info("Info stored: #{server_id}")
		:ok
	      {:error, reason} ->
		Logger.info("Unable to store info: #{server_id} Reason: #{inspect(reason)}")
		{:error, reason}
	    end
	  {:ok, last_info} ->
	    case Collector.ProcessTravianMap.compare_server_info(last_info, enriched_info) do
	      :not_necessary -> 
		Logger.info("Not necessary to store info: #{server_id}")
		:ok
	      new_info -> 
		case Storage.store_info(root_folder, server_id, now, new_info) do
		# case SnapshotEncoder.encode_info(new_info, root_folder, now, server_id) do
		  :ok ->
		    Logger.info("Info stored: #{server_id}")
		    :ok
		  {:error, reason} ->
		    Logger.info("Unable to store info: #{server_id} Reason: #{inspect(reason)}")
		    {:error, reason}
		end
	    end
	end
    end
  end
end
