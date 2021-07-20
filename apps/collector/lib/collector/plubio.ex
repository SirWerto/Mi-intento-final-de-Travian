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

  @tasksupopts [max_restarts: 30, max_seconds: 5, max_children: :infinity]

  @tasksupspecs %{
      :id => "tasksup",
      :start => {Task.Supervisor, :start_link, [@tasksupopts]},
      :restart => :permanent,
      :shutdown => 5_000,
      :type => :supervisor
    }



  def start_link() do
    :gen_statem.start_link({:local, __MODULE__}, __MODULE__, [], [])
  end


  @impl true
  def callback_mode() do
    [:state_functions, :state_enter]
  end

  @impl true
  def init([]) do
    Logger.debug("launching Plubio")
    send(self(), :start_suptask)
    {:ok, :waiting, %__MODULE__{}}
  end

  ### STATES

  def waiting(:enter, _OldState, state) do
    {:next_state, :waiting, state}
  end

  def waiting(:info , :start_suptask, state) do
    Logger.debug("launching suptask")
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
    new_state = Collector.PlubioState.handle_subscription(state, f_pid)
    {:next_state, :waiting, new_state, {:reply, from, {:ok, :subscribed}}}
  end

  def waiting({:call, from}, {:unsubscribe, f_pid}, state) do
    new_state = Collector.PlubioState.handle_unsubscription(state, f_pid)
    {:next_state, :waiting, new_state, {:reply, from, {:ok, :unsubscribed}}}
  end

  def waiting({:call, from}, :force_collecting, state) do
    {:next_state, :collecting, state, {:reply, from, {:ok, :collecting}}}
  end


  def waiting(:info , {:DOWN, ref, :process, f_pid, _reason}, state) do
    new_state = Collector.PlubioState.handle_down_subscription(state, f_pid, ref)
    {:next_state, :waiting, new_state}
  end



  def collecting(:enter, :waiting, state) do
    Logger.info("Enteríng on collecting mode")
    {:ok, urltasks} = Collector.ScrapUrls.get_current_urls()
    new_state = Collector.PlubioState.spawn_urltasks(state, urltasks)
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
    new_state = Collector.PlubioState.handle_subscription(state, f_pid)
    {:next_state, :collecting, new_state, {:reply, from, {:ok, :subscribed}}}
  end

  def collecting({:call, from}, {:unsubscribe, f_pid}, state) do
    new_state = Collector.PlubioState.handle_unsubscription(state, f_pid)
    {:next_state, :collecting, new_state, {:reply, from, {:ok, :unsubscribed}}}
  end

  def collecting({:call, from}, :force_collecting, state) do
    {:next_state, :collecting, state, {:reply, from, {:ok, :collecting}}}
  end

  def collecting(:cast , {:collected, f_pid, url}, state) do
    Logger.debug("Collection " <> url <> " ended")
    new_state = Collector.PlubioState.handle_end_collecting(state, f_pid, url)
    case Collector.PlubioState.collection_done?(new_state) do
      true ->
	Logger.info("Collection ended")
	{:next_state, :waiting, new_state}
      false -> {:next_state, :collecting, new_state}
    end
  end

  def collecting(:info , {:DOWN, ref, :process, f_pid, _reason}, state) do
    new_state = Collector.PlubioState.handle_down_collecting(state, f_pid, ref)
    case Collector.PlubioState.collection_done?(new_state) do
      true ->
	Logger.info("Collection ended")
	{:next_state, :waiting, new_state}
      false -> {:next_state, :collecting, new_state}
    end
  end

end
