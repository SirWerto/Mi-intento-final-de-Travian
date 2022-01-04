defmodule Medusa.Producer do
  use GenStage

  @moduledoc """
  This module is the gateway to Medusas's pipeline. It's a `GenStage` `:producer` and also
  acts as `GenServer` holding the application logic.
  """


### PUBLIC API

  @doc """
  Starts a `Medusa.Producer` process linked to the current process.
  """
  @spec start_link() :: GenServer.on_start()
  def start_link() do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end


  @doc """
  Sends players_id to `Medusa.Producer` for being evalutated.
  """
  @spec eval_players(players_id :: [Medusa.Types.player_id()]) :: :ok
  def eval_players(players_id)
  def eval_players([]) do
    :ok
  end
  def eval_players(players_id) do
    GenStage.cast(__MODULE__, {:eval_players, players_id})
  end

### CALLBACKS
  @impl true
  def init([]) do
    {:producer, {:queue.new(), 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  @impl true
  def handle_cast({:eval_players, players_id}, {queue, demand}) do
    queue = Enum.reduce(players_id, queue, fn x, acc -> :queue.in(x, acc) end)
    {queue, demand, events} = dispatch_events(queue, demand)
    {:noreply, events, {queue, demand}}
  end

  @impl true
  def handle_demand(new_demand, {queue, demand}) do
    {queue, demand, events} = dispatch_events(queue, demand + new_demand)
    {:noreply, events, {queue, demand}}
  end

### PRIVATE FUNCTIONS

  @spec dispatch_events(queue :: :queue.queue(), demand :: non_neg_integer())
  :: {:queue.queue(), non_neg_integer(), [Medusa.Types.player_id()]}
  defp dispatch_events(queue, demand) do
    dispatch_events(queue, demand, [])
  end

  @spec dispatch_events(queue :: :queue.queue(), demand :: non_neg_integer(), events :: [Medusa.Types.player_id()])
  :: {:queue.queue(), non_neg_integer(), [Medusa.Types.player_id()]}
  defp dispatch_events(queue, demand, events)
  defp dispatch_events(queue, 0, events) do
    {queue, 0, events}
  end
  defp dispatch_events(queue, demand, events) do
    case :queue.is_empty(queue) do
      true -> {queue, demand, events}
      false ->
	{{:value, event}, queue} = :queue.out(queue)
	demand = demand - 1
	events = [event | events]
	dispatch_events(queue, demand, events)
    end
  end


end
