defmodule Collector.GenCollector do
  use GenServer
  require Logger


  @milliseconds_in_day 24*60*60*1000
  @milliseconds_in_hour 60*60*1000
  @time_between_tries 10_000

  @random_datetime ~U[2022-01-04 17:27:49.080543Z]

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
    {:ok, []}
  end

  @impl true
  def handle_call(:milliseconds_until_collect, _from, tref), do: {:reply, :erlang.read_timer(tref), tref}
  def handle_call(_msg, _from, tref), do: {:noreply, tref}

  @impl true
  def handle_info(:init, []) do
    collection_hour = Application.fetch_env!(:collector, :collection_hour)
    wait_time = time_until_collection(collection_hour) 
    tref = :erlang.send_after(wait_time, self(), :collect)
    {:noreply, tref}
  end


  def handle_info(:collect, _state) do
    Logger.debug("Collection started")
    case handle_collection() do
      :ok ->
	collection_hour = Application.fetch_env!(:collector, :collection_hour)
	wait_time = time_until_collection(collection_hour) 
	tref = :erlang.send_after(wait_time, self(), :collect)
	{:noreply, tref}
      {:error, reason} ->
	Logger.info("(GenCollector)Unable to collect: " <> Kernel.inspect(reason))
	tref = :erlang.send_after(@time_between_tries, self(), :collect)
	{:noreply, tref}
    end
  end

  def handle_info(_msg, state), do: {:noreply, state}

  @spec handle_collection() :: :ok | {:error, any()}
  defp handle_collection() do
    case :travianmap.get_urls() do
      {:error, reason} -> {:error, reason}
      {:ok, urls} -> 
	bad_launched_tasks = urls
	|> Enum.map(&start_worker/1)
	|> Enum.filter(&(&1 != :ok))

	for bad_task <- bad_launched_tasks, do: Logger.info("(GenCollector)Unable to launch task: " <> Kernel.inspect(bad_task))
	:ok
    end
  end

  @spec start_worker(url :: binary()) :: :ok | {:ignore, binary()} | {:error, any()}
  defp start_worker(url) do
    case Task.Supervisor.start_child(Collector.TaskSupervisor, Collector.GenWorker, :start_link, [url, @random_datetime]) do
      {:ok, _pid} -> :ok
      :ignore -> {:ignore, url}
      {:error, reason} -> {:error, {url, reason}}
    end
  end



  defp time_until_collection(collection_hour), do: time_until_collection(collection_hour, Time.utc_now())

  defp time_until_collection(ch, ch), do: 0
  defp time_until_collection(ch, now) when ch > now, do: Time.diff(ch, now, :millisecond)
  defp time_until_collection(ch, now), do: @milliseconds_in_day + Time.diff(ch, now, :millisecond)

end
