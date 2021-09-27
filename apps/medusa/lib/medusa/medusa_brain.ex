defmodule Medusa.Brain do
  use GenServer

  @moduledoc """
  This module defines the logic behind Medusa. Also, It stores the results and some valid information
  about model predictions. Probably, It will change from GenServer to GenStage to become a producer
  """

  defstruct subscribers: %{}, collecting: false, collection_datetime: :nil, players: %{}

  @type inactive :: {:inactive, pos_integer()}
  @type active :: {:active, float()}
  @type future_inactive :: {:future_inactive, float()}
  @type not_evaluated :: :not_yet | :not_enought_days
  @type condition :: inactive() | active() | future_inactive() | not_evaluated()

  @type t :: %__MODULE__{
    collecting: false | true,
    collection_datetime: :nil | DateTime.t(),
    subscribers: %{pid() => reference()},
    players: %{String.t() => condition()}
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

  @spec subscribers() :: {:ok | :error, any()}
  def subscribers() do
    try do
      GenServer.call(__MODULE__, :subscribers)
    rescue 
      e in RuntimeError -> {:error, e}
    end
  end


  @spec new_players_id(players_id :: [String.t()]) :: :ok
  def new_players_id(players_id) do
    GenServer.cast(__MODULE__, {:new_players_id, players_id})
  end

  @spec evaluated_players() :: {:ok, %{String.t() => condition()}} | {:error, any()}
  def evaluated_players() do
    try do
      GenServer.call(__MODULE__, :players)
    rescue 
      e in RuntimeError -> {:error, e}
    end
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
  def handle_call({:subscribe, spid}, _from, state)do
    ref = Process.monitor(spid)
    new_subscribers = Map.put(state.subscribers, spid, ref)
    new_state = Map.put(state, :subscribers, new_subscribers)
    {:reply, {:ok, :subscribed}, new_state}
  end


  @impl true
  def handle_call(:subscribers, _from, state) do
    {:reply, Map.keys(state.subscribers), state}
  end

  @impl true
  def handle_call(:players, _from, state) do
    {:reply, state.players, state}
  end

  @impl true
  def handle_call(_msg, _from, state) do
    {:noreply, state}
  end


  @impl true
  def handle_cast({:new_players_id, players_id}, state) do
    new_players = Enum.reduce(players_id, state.players, fn p_id, players -> Map.put_new(players, p_id, :not_yet) end)
    new_state = Map.put(state, :players, new_players)
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
