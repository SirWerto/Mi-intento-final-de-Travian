defmodule Collector.Plubio do
  @behaviour :gen_statem
  require Logger

  defstruct tsup: :nil, url_status: %{}, task_status: %{}, subscriptors: %{}

  @type t :: %__MODULE__{
    tsup: pid() | :nil, 
    url_status: %{Collector.url() => Collector.url_status()},
    task_status: %{pid() => {reference(), Collector.url()}},
    subscriptors: %{pid() => reference()}
  }

  @tasksupspecs %{
      :id => "tasksup",
      :start => {Task.Supervisor, :start_link, []},
      :restart => :permanent,
      :shutdown => 5_000,
      :type => :supervisor
    }


  def start_link() do
    :gen_statem.start_link({:local, __MODULE__}, __MODULE__, [], [])
  end


  @impl true
  def callback_mode() do
    :state_functions
  end

  @impl true
  def init([]) do
    send(self(), :start_suptask)
    {:ok, :waiting, %__MODULE__{}}
  end

  ### STATES


  def waiting(:info , :start_suptask, state) do
    case Supervisor.start_child(Collector.Supervisor, @tasksupspecs) do
      {:ok, tsup} ->
	new_state = Map.put(state, :tsup, tsup)
	{:next_state, :waiting, new_state}
      {:error, reason} ->
     	{:next_state, :waiting, state, {:stop, reason}}
    end
  end

  def waiting({:call, from}, :current_state, state) do
    {:next_state, :waiting, state, {:reply, from, :waiting}}
  end

  def waiting({:call, from}, :subscribers, state) do
    {:next_state, :waiting, state, {:reply, from, {:ok, Map.keys(state.subscriptors)}}}
  end


  def waiting({:call, from}, {:subscribe, f_pid}, state) do
    new_state = handle_subscription(state, f_pid)
    {:next_state, :waiting, new_state, {:reply, from, {:ok, :subscribed}}}
  end

  def waiting({:call, from}, {:unsubscribe, f_pid}, state) do
    new_state = handle_unsubscription(state, f_pid)
    {:next_state, :waiting, new_state, {:reply, from, {:ok, :unsubscribed}}}
  end

  def waiting({:call, from}, :force_collecting, state) do
    {:next_state, :collecting, state, {:reply, from, {:ok, :collecting}}}
  end


  def waiting(:info , {:DOWN, ref, :process, f_pid, _reason}, state) do
    new_state = handle_down_subscription(state, f_pid, ref)
    {:next_state, :waiting, new_state}
  end



  def collecting(:enter, _old_state, state) do
    Logger.info("Enteríng on collecting mode")
    {:ok, urltasks} = Collector.ScrapUrls.get_current_urls()
    new_state = spawn_urltasks(state, urltasks)
    Logger.info("Task launched")
    {:next_state, :collecting, new_state}
  end

  def collecting({:call, from}, :current_state, state) do
    {:next_state, :collecting, state, {:reply, from, :collecting}}
  end

  def collecting({:call, from}, :subscribers, state) do
    {:next_state, :collecting, state, {:reply, from, {:ok, Map.keys(state.subscriptors)}}}
  end

  def collecting({:call, from}, {:subscribe, f_pid}, state) do
    new_state = handle_subscription(state, f_pid)
    {:next_state, :collecting, new_state, {:reply, from, {:ok, :subscribed}}}
  end

  def collecting({:call, from}, {:unsubscribe, f_pid}, state) do
    new_state = handle_unsubscription(state, f_pid)
    {:next_state, :collecting, new_state, {:reply, from, {:ok, :unsubscribed}}}
  end

  def collecting({:call, from}, :force_collecting, state) do
    {:next_state, :collecting, state, {:reply, from, {:ok, :collecting}}}
  end

  def collecting(:info , {:DOWN, ref, :process, f_pid, _reason}, state) do
    new_state = handle_down_collecting(state, f_pid, ref)
    {:next_state, :collecting, new_state}
  end

  ### Private functions

  @spec handle_subscription(state :: __MODULE__.t(), f_pid :: pid()) :: __MODULE__.t()
  defp handle_subscription(state, f_pid) do
    case Map.has_key?(state.subscriptors, f_pid) do
      true -> state
      false ->
	ref = Process.monitor(f_pid)
	new_subscriptors = Map.put(state.subscriptors, f_pid, ref)
	Map.put(state, :subscriptors, new_subscriptors)
    end
  end

  @spec handle_unsubscription(state :: __MODULE__.t(), f_pid :: pid()) :: __MODULE__.t()
  defp handle_unsubscription(state, f_pid) do
    case Map.has_key?(state.subscriptors, f_pid) do
      true -> 
	{ref, new_subscriptors} = Map.pop!(state.subscriptors, f_pid)
	Process.demonitor(ref, [:flush])
	Map.put(state, :subscriptors, new_subscriptors)
      false -> state
    end
  end

  @spec handle_down_collecting(state :: __MODULE__.t(), f_pid :: pid(), ref :: reference()) :: __MODULE__.t()
  defp handle_down_collecting(state, f_pid, ref) do
    case Map.has_key?(state.task_status, f_pid) do
      true -> 
	{{^ref, url}, new_task_status} = Map.pop!(state.task_status, f_pid)
	new_url_status = Map.put(state.url_status, url, :error)
	new_state = Map.put(state, :task_status, new_task_status)
	|> Map.put(:url_status, new_url_status)
	new_state
      false -> handle_down_subscription(state, f_pid, ref)
    end
  end

  @spec handle_down_subscription(state :: __MODULE__.t(), f_pid :: pid(), ref :: reference()) :: __MODULE__.t()
  defp handle_down_subscription(state, f_pid, ref) do
    case Map.has_key?(state.subscriptors, f_pid) do
      true ->
	{^ref, new_subscriptors} = Map.pop!(state.subscriptors, f_pid)
	new_state = Map.put(state, :subscriptors, new_subscriptors)
	new_state
      false -> state #not a message for us
    end
  end


  @spec spawn_monitor_urltask(state :: __MODULE__.t(), urltask :: {Collector.url, DateTime.t()}) :: {:ok, Collector.url(), pid(), reference()} | {:error, Collector.url(), any()} 
  defp spawn_monitor_urltask(state, urltask = {url, _init_date}) do
    case Task.Supervisor.start_child(state.tsup, Collector.Worker, :collect, [self(), urltask]) do
      {:ok, cpid} ->
	ref = Process.monitor(cpid)
	{:ok, url, cpid, ref}
      {:error, {:already_started, _cpid}} -> {:error, url, :already_started}
      {:error, :max_children} -> {:error, url, :max_children}
      some -> {:error, url, some}
    end
  end

  @spec spawn_urltasks(__MODULE__.t(), [{Collector.url, DateTime.t()}]) :: __MODULE__.t()
  defp spawn_urltasks(state, urltasks) do
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
