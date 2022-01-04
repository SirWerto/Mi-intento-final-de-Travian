defmodule Collector.GenWorker do
  use GenServer
  require Logger


  @max_tries 3


  @delay_max 300_000
  @delay_min 5_000

  @spec start_link(url :: binary(), init_date :: DateTime.t()) :: GenServer.on_start()
  def start_link(url, init_date), do: GenServer.start_link(__MODULE__, [url, init_date])
  
  @spec stop(pid :: pid(), reason :: term(), timeout :: timeout()) :: :ok
  def stop(pid, reason \\ :normal, timeout \\ 5000), do: GenServer.stop(pid, reason, timeout)


  @impl true
  def init([url, init_date]) do
    send(self(), :collect)
    {:ok, {url, init_date, 0}}
  end


  @impl true
  def handle_call(_msg, _from, state), do: {:noreply, state}

  @impl true
  def handle_cast(_msg, state), do: {:noreply, state}


  @impl true
  def handle_info(:collect, {_url, _init_date, @max_tries}), do: {:stop, :reached_max_tries, []}
  def handle_info(:collect, {url, init_date, tries}) do
    Process.sleep(:rand.uniform(@delay_max - @delay_min) + @delay_min)
    case collect(url, init_date) do
      :ok -> {:stop, :normal, []}
      {:error, reason} ->
	Logger.info("(GenWorker)Unable to collect: " <> url <> "\nReason: " <> IO.inspect(reason))
	send(self(), :collect)
	{:noreply, {url, init_date, tries+1}}
    end
  end
  def handle_info(_msg, state), do: {:noreply, state}


  @spec collect(url :: binary(), init_date :: DateTime.t()) :: :ok | {:error, any()}
  defp collect(url, init_date) do
    case :travianmap.get_info(url) do
      {:error, reason} -> {:error, reason}
      {:ok, aditional_info} -> 
	case :travianmap.get_map(url) do
	  {:error, reason} -> {:error, reason}
	  {:ok, server_map} -> 
	    records = :travianmap.parse_map(server_map, :filter)
	    case handle_inserts(url, init_date, aditional_info, records) do
	      {:error, reason} -> {:error, reason}
	      {:ok, players_id} -> 
		Medusa.eval_players(players_id)
		Logger.info("(GenWorker)Successfully collected: " <> url)
		:ok
	    end
	end
    end
  end

  @spec handle_inserts(url :: binary(), init_date :: DateTime.t(), aditional_info :: map(), records :: [tuple()]) :: {:ok, [binary()]} | {:error, any()}
  defp handle_inserts(url, init_date, aditional_info, records) do
    try do

      server_dict = for record <- records, do: Collector.ProcessTravianMap.tuple_to_map(record)

      server_id = Collector.ProcessTravianMap.create_server_id(url, init_date)
      server = Collector.ProcessTravianMap.process_server(server_id, url, init_date, aditional_info)
      alliances = Collector.ProcessTravianMap.process_alliances(server_id, server_dict)
      players = Collector.ProcessTravianMap.process_players(server_id, server_dict)
      villages = Collector.ProcessTravianMap.process_villages(server_id, server_dict)
      a_p = Collector.ProcessTravianMap.process_a_ps(server_id, server_dict)
      p_v = Collector.ProcessTravianMap.process_p_vs(server_id, server_dict)

      Collector.Queries.insert_or_update_server!(server)
      Collector.Queries.insert_or_update_alliances!(alliances) |> TDB.Repo.transaction()
      Collector.Queries.insert_or_update_players!(players) |> TDB.Repo.transaction()
      Collector.Queries.insert_or_update_villages!(villages) |> TDB.Repo.transaction()
      Collector.Queries.insert_or_update_a_p!(a_p) |> TDB.Repo.transaction()
      Collector.Queries.insert_or_update_p_v!(p_v) |> TDB.Repo.transaction()
      players_id = for player <- players, do: player.data.id
      {:ok, players_id}
    rescue
      error in RuntimeError -> {:error, error}
    end
  end

end
