defmodule Collector.GenCollector do
  use GenServer
  require Logger


  @milliseconds_in_hour 60*60*1000
  @time_between_tries 10_000
  @max_tries 3

  defstruct [:tref, :active_p]

  @spec start_link() :: GenServer.on_start()
  def start_link(), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)


  @spec stop(pid :: pid(), reason :: term(), timeout :: timeout()) :: :ok
  def stop(pid, reason \\ :normal, timeout \\ 5000), do: GenServer.stop(pid, reason, timeout)

  @spec collect() :: :collect
  def collect(), do: send(__MODULE__, :collect)

  @spec hours_until_collect() :: {:ok, float()} | {:error, :no_timer}
  def hours_until_collect() do
    case GenServer.call(__MODULE__, :milliseconds_until_collect) do
      false -> {:error, :no_timer}
      milliseconds -> {:ok, milliseconds/@milliseconds_in_hour}
    end
  end


  @impl true
  def init([]) do
    send(self(), :init)
    {:ok, %__MODULE__{active_p: %{}}, {:continue, []}}
  end

  @impl true
  def handle_continue(_continue, state) do
    collection_hour = Application.fetch_env!(:collector, :collection_hour)
    wait_time = Collector.Utils.time_until_collection(collection_hour) 
    tref = :erlang.send_after(wait_time, self(), :collect)
    state = Map.put(state, :tref, tref)
    {:noreply, state}
  end

  @impl true
  def handle_call(:milliseconds_until_collect, _from, state), do: {:reply, :erlang.read_timer(state.tref), state}
  def handle_call(_msg, _from, state), do: {:noreply, state}


  @impl true
  def handle_info(:collect, state) do
    Logger.info("Collection started")
    case handle_collection() do
      {:ok, monitor_pids} ->
	active_p = Map.merge(state.active_p, monitor_pids)
	collection_hour = Application.fetch_env!(:collector, :collection_hour)
	wait_time = Collector.Utils.time_until_collection(collection_hour) 
	tref = :erlang.send_after(wait_time, self(), :collect)
	{:noreply, %__MODULE__{tref: tref, active_p: active_p}}
      {:error, reason} ->
	Logger.info("(GenCollector)Unable to collect: " <> Kernel.inspect(reason))
	tref = :erlang.send_after(@time_between_tries, self(), :collect)
	state = Map.put(state, :tref, tref)
	{:noreply, state}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, :normal}, state) do
    case Map.has_key?(state.active_p, pid) do
      true -> {:noreply, handle_monitor_normal(state, pid)}
      false -> {:noreply, state}
    end
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    case Map.has_key?(state.active_p, pid) do
      true -> {:noreply, handle_monitor_nonormal(state, pid, reason)}
      false -> {:noreply, state}
    end
  end

  def handle_info(_msg, state), do: {:noreply, state}

  defp handle_monitor_normal(state, pid) do
    active_p = Map.delete(state.active_p, pid)
    state = Map.put(state, :active_p, active_p)
    state
  end


  defp handle_monitor_nonormal(state, pid, reason) do
    {_ref, server_id, tries, type} = Map.get(state.active_p, pid)
    Logger.notice("Unable to get #{inspect(type)} server: #{server_id} reason: #{inspect(reason)}")
    case tries do
      @max_tries -> 
	Logger.notice("Unable to launch #{inspect(type)} server: #{server_id} reason: @max_tries")
	active_p = Map.delete(state.active_p, pid)
	state = Map.put(state, :active_p, active_p)
	state
      _ -> 
	case start_one_worker(server_id, type) do
	  {:ok, {new_pid, ref}} ->
	    Logger.notice("Launched #{inspect(type)} server: #{server_id}")
	    active_p = state.active_p
	    |> Map.delete(pid)
	    |> Map.put(new_pid, {ref, server_id, tries+1, type})
	    state = Map.put(state, :active_p, active_p)
	    state
	  {_, reason} ->
	    Logger.notice("Unable to launch #{inspect(type)} server: #{server_id} reason: #{reason}")
	    active_p = Map.delete(state.active_p, pid)
	    state = Map.put(state, :active_p, active_p)
	    state
	end
    end
  end


  @spec handle_collection() :: {:ok, %{pid() => any()}} | {:error, any()}
  defp handle_collection() do
    case :travianmap.get_urls() do
      {:error, reason} -> {:error, reason}
      {:ok, urls} -> 

	process = Enum.flat_map(urls, &start_worker/1)

	process
	|> Enum.filter(&(&1 == :error))
	|> Enum.map(fn {:error, {server_id, type, reason}} -> Logger.notice("Unable to launch #{inspect(type)} server: #{server_id} reason: #{reason}") end)

	monitor_pids = for {:ok, {pid, ref, server_id, type}} <- process, into: %{}, do: {pid, {ref, server_id, 0, type}}
	{:ok, monitor_pids}
    end
  end

  @spec start_worker(server_id :: TTypes.server_id()) :: [:ok | {:ignore, binary()} | {:error, any()}]
  defp start_worker(server_id) do
    [Collector.CollectorSupervisor.start_worker_info(server_id),
     Collector.CollectorSupervisor.start_worker_snapshot(server_id)]
  end

  defp start_one_worker(server_id, :info), do: Collector.CollectorSupervisor.start_worker_info(server_id)
  defp start_one_worker(server_id, :snapshot), do: Collector.CollectorSupervisor.start_worker_snapshot(server_id)
end
