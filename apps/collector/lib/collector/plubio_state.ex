defmodule Collector.PlubioState do
  require Logger


  @type t :: Collector.Plubio.t()

  @spec handle_subscription(state :: __MODULE__.t(), f_pid :: pid()) :: __MODULE__.t()
  def handle_subscription(state, f_pid) do
    case Map.has_key?(state.subscriptors, f_pid) do
      true -> state
      false ->
	ref = Process.monitor(f_pid)
	new_subscriptors = Map.put(state.subscriptors, f_pid, ref)
	Map.put(state, :subscriptors, new_subscriptors)
    end
  end

  @spec handle_unsubscription(state :: __MODULE__.t(), f_pid :: pid()) :: __MODULE__.t()
  def handle_unsubscription(state, f_pid) do
    case Map.has_key?(state.subscriptors, f_pid) do
      true -> 
	{ref, new_subscriptors} = Map.pop!(state.subscriptors, f_pid)
	Process.demonitor(ref, [:flush])
	Map.put(state, :subscriptors, new_subscriptors)
      false -> state
    end
  end

  @spec handle_end_collecting(state :: __MODULE__.t(), f_pid :: pid(), url :: Collector.url()) :: __MODULE__.t()
  def handle_end_collecting(state, f_pid, url) do
    {{_ref, ^url}, new_task_status} = Map.pop!(state.task_status, f_pid)
    new_url_status = Map.put(state.url_status, url, :done)
    new_state = Map.put(state, :url_status, new_url_status)
    |> Map.put(:task_status, new_task_status)
    new_state
  end

  @spec handle_down_collecting(state :: __MODULE__.t(), f_pid :: pid(), ref :: reference()) :: __MODULE__.t()
  def handle_down_collecting(state, f_pid, ref) do
    case Map.has_key?(state.task_status, f_pid) do
      true -> 
	{{^ref, url}, new_task_status} = Map.pop!(state.task_status, f_pid)
	Logger.debug("handle down worker " <> url)
	new_url_status = Map.put(state.url_status, url, :error)
	new_state = Map.put(state, :task_status, new_task_status)
	|> Map.put(:url_status, new_url_status)
	new_state
      false -> handle_down_subscription(state, f_pid, ref)
    end
  end

  @spec handle_down_subscription(state :: __MODULE__.t(), f_pid :: pid(), ref :: reference()) :: __MODULE__.t()
  def handle_down_subscription(state, f_pid, ref) do
    case Map.has_key?(state.subscriptors, f_pid) do
      true ->
	{^ref, new_subscriptors} = Map.pop!(state.subscriptors, f_pid)
	new_state = Map.put(state, :subscriptors, new_subscriptors)
	new_state
      false -> state #not a message for us
    end
  end

  @spec collection_done?(state :: __MODULE__.t()) :: boolean()
  def collection_done?(state) do
    case length(Map.keys(state.task_status)) do
      0 -> true
      _ -> false
    end
  end



  ### Launch tasks
  @spec spawn_monitor_urltask(state :: __MODULE__.t(), urltask :: {Collector.url, DateTime.t()}) :: {:ok, Collector.url(), pid(), reference()} | {:error, Collector.url(), any()} 
  defp spawn_monitor_urltask(state, urltask = {url, _init_date}) do
    {tsup, _ref} = state.tsup
    case Task.Supervisor.start_child(tsup, Collector.Worker, :collect, [self(), urltask]) do
      {:ok, cpid} ->
	Logger.debug("added to the suppervisor")
	ref = Process.monitor(cpid)
	{:ok, url, cpid, ref}
      {:error, {:already_started, _cpid}} -> {:error, url, :already_started}
      {:error, :max_children} -> {:error, url, :max_children}
      some -> {:error, url, some}
    end
  end

  @spec spawn_urltasks(__MODULE__.t(), [{Collector.url, DateTime.t()}]) :: __MODULE__.t()
  def spawn_urltasks(state, urltasks) do
    {new_url_status, new_task_status} = Enum.map(urltasks, fn urltask -> spawn_monitor_urltask(state, urltask) end)
    |> Enum.reduce({%{}, %{}},&handle_spawns/2)

    new_state = Map.put(state, :url_status, new_url_status)
    |> Map.put(:task_status, new_task_status)
    new_state
  end

  @spec handle_spawns({:ok, Collector.url, pid(), reference()}, {map(), map()}) :: {map(), map()}
  defp handle_spawns({:ok, url, cpid, ref}, {urls, tasks}) do
    {Map.put(urls, url, :collecting), Map.put(tasks, cpid, {ref, url})}
  end
  @spec handle_spawns({:error, Collector.url, any()}, {map(), map()}) :: {map(), map()}
  defp handle_spawns({:error, url, _reason}, {urls, tasks}) do
    {Map.put(urls, url, :error), tasks}
  end



end
