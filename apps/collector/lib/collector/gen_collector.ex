defmodule Collector.GenCollector do
  use GenServer
  require Logger


  @milliseconds_in_day 24*60*60*1000
  @time_between_tries 10_000

  @random_datetime ~U[2022-01-04 17:27:49.080543Z]

  @spec start_link() :: GenServer.on_start()
  def start_link(), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)


  @spec stop(pid :: pid(), reason :: term(), timeout :: timeout()) :: :ok
  def stop(pid, reason \\ :normal, timeout \\ 5000), do: GenServer.stop(pid, reason, timeout)

  @spec collect() :: :collect
  def collect(), do: send(__MODULE__, :collect)


  @impl true
  def init([]) do
    send(self(), :init)
    {:ok, []}
  end

  @impl true
  def handle_info(:init, []) do
    collection_hour = Application.fetch_env!(:collector, :collection_hour)
    wait_time = time_until_collection(collection_hour) 
    case :timer.send_after(wait_time, :collect) do
      {:ok, tref} -> {:noreply, tref}
      {:error, reason} -> {:stop, reason, []}
    end
  end


  def handle_info(:collect, _state) do
    Logger.debug("Collection started")
    case handle_collection() do
      :ok ->
	collection_hour = Application.fetch_env!(:collector, :collection_hour)
	wait_time = time_until_collection(collection_hour) 
	case :timer.send_after(wait_time, :collect) do
	  {:ok, tref} -> {:noreply, tref}
	  {:error, reason} -> {:stop, reason, []}
	end

      {:error, reason} ->
	Logger.info("(GenCollector)Unable to collect: " <> IO.inspect(reason))
	:timer.send_after(@time_between_tries, :collect)
	{:noreply, []}
    end
  end

  def handle_info(_msg, state), do: {:noreply, state}

  @spec handle_collection() :: :ok | {:error, any()}
  defp handle_collection() do
    case :travianmap.get_urls() do
      {:error, reason} -> {:error, reason}
      {:ok, urls} -> 
	urls
	|> Enum.map(&start_worker/1)
	|> Enum.filter(&(&1 != :ok))
	|> Enum.map(fn x -> Logger.info("(GenCollector)Unable to launch task: " <> IO.inspect(x)) end)
	:ok
    end
  end

  @spec start_worker(url :: binary()) :: :ok | {:ignore, binary()} | {:error, any()}
  defp start_worker(url) do
    case Task.Supervisor.start_child(Collector.TaskSupervisor, Collector.GenWorker, :start_link, [url, @random_datetime]) do
      {:ok, pid} ->
	IO.inspect(Process.info(pid))
	:ok
      :ignore -> {:ignore, url}
      {:error, reason} -> {:error, {url, reason}}
    end
  end



  defp time_until_collection(collection_hour), do: time_until_collection(collection_hour, Time.utc_now())

  defp time_until_collection(ch, ch), do: 0
  defp time_until_collection(ch, now) when ch > now, do: Time.diff(ch, now, :millisecond)
  defp time_until_collection(ch, now), do: @milliseconds_in_day + Time.diff(now, ch, :millisecond)

end
