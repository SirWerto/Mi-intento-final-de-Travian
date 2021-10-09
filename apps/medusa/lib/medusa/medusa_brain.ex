defmodule Medusa.Brain do
  use GenServer

  @moduledoc """
  This module defines the logic behind Medusa. Also, It stores the results and some valid information
  about model predictions. Probably, It will change from GenServer to GenStage to become a producer
  """

  defstruct subscribers: %{}, queue: :queue.new(), demand: 0


  @type t :: %__MODULE__{
    subscribers: %{pid() => reference()},
    queue: :queue.queue(),
    demand: non_neg_integer()
  }

### PUBLIC API

  @spec start_link() :: GenServer.on_start()
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec subscribe(spid :: pid()) :: {:ok, :subscribed} | {:error, any()}
  def subscribe(spid) do
    try do
      GenServer.call(__MODULE__, {:subscribe, spid})
    rescue 
      e in RuntimeError -> {:error, e}
    end
  end

  @spec unsubscribe(spid :: pid()) :: {:ok, :unsubscribed} | {:error, any()}
  def unsubscribe(spid) do
    try do
      GenServer.call(__MODULE__, {:unsubscribe, spid})
    rescue 
      e in RuntimeError -> {:error, e}
    end
  end

  @spec subscribers() :: {:ok | :error, any()}
  def subscribers() do
    try do
      GenServer.call(__MODULE__, :subscribers)
    rescue 
      e in RuntimeError -> {:error, e}
    end
  end


  @spec send_players(players_id :: [String.t()]) :: :ok
  def send_players(players_id) do
    GenServer.cast(__MODULE__, {:players, players_id})
  end

### CALLBACKS
  @impl true
  def init([]) do
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_call({:subscribe, spid}, _from, state) when is_map_key(state.subscribers, spid) do
    {:reply, {:ok, :subscribed}, state}
  end

  @impl true
  def handle_call({:subscribe, spid}, _from, state) do
    case Map.has_key?(state.subscribers, spid) do
      true -> {:reply, {:ok, :subscribed}, state}
      false ->
	ref = Process.monitor(spid)
	new_subscribers = Map.put(state.subscribers, spid, ref)
	new_state = Map.put(state, :subscribers, new_subscribers)
	{:reply, {:ok, :subscribed}, new_state}
    end
  end

  @impl true
  def handle_call({:unsubscribe, spid}, _from, state) do
    case Map.has_key?(state.subscribers, spid) do
      false -> {:reply, {:ok, :unsubscribed}, state}
      true -> 
	Process.demonitor(Map.get(state.subscribers, spid), [:flush])
	new_subscribers = Map.delete(state.subscribers, spid)
	new_state = Map.put(state, :subscribers, new_subscribers)
	{:reply, {:ok, :unsubscribed}, new_state}
    end
  end


  @impl true
  def handle_call(:subscribers, _from, state) do
    {:reply, Map.keys(state.subscribers), state}
  end

  @impl true
  def handle_call(_msg, _from, state) do
    {:noreply, state}
  end


  @impl true
  def handle_cast({:players, players_id}, state) do
    new_queue = Enum.reduce(players_id, state.queue, fn p_id, queue -> :queue.in(p_id, queue) end)
    new_state = Map.put(state, :queue, new_queue)
    {:noreply, new_state}
  end


  @impl true
  def handle_info({:DOWN, _ref, :process, spid, _reason}, state) when is_map_key(state.subscribers, spid) do
    new_subscribers = Map.delete(state.subscribers, spid)
    new_state = Map.put(state, :subscribers, new_subscribers)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
### PRIVATE FUNCTIONS

end
