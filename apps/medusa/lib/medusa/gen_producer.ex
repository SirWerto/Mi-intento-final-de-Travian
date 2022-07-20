defmodule Medusa.GenProducer do
  use GenStage

  require Logger

  defstruct [:collector_ref, collector_status: :inactive, status: :inactive, subs: %{}, pending_events: []]


  @type t :: %__MODULE__{
    collector_status: :active | :inactive,
    status: :active | :inactive,
    collector_ref: nil | reference(),
    pending_events: [TTypes.server_id],
    subs: map()
  }

  @spec start_link() :: GenServer.on_start()
  def start_link() do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  # def subscribe(), do: ok
  # def unsubscribe(), do: ok

  @impl true
  def init([]) do
    state = %__MODULE__{}
    send(self(), :init)
    {:producer, state}
  end

  @impl true
  def handle_demand(_demand, state), do: {:noreply, [], state}

  @impl true
  def handle_info(:init, state) do
    case Collector.subscribe() do
      {:ok, ref} ->
	new_state = Map.put(state, :collector_ref, ref)
	{:noreply, [], new_state}
      {:error, reason} ->
	Logger.warning(%{msg: "Medusa.GenProducer unable to subscribe to Collector", reason: reason, args: state})
	{:stop, :normal, state}
    end
  end
  def handle_info({:DOWN, ref, :process, _pid, reason}, state = %{collector_ref: ref}) do
    Logger.warning(%{msg: "Collector down, relaunching Medusa, events running will be lost", reason: reason, args: state})
    {:stop, :normal, state}
  end
  ######## COLLECTOR EVENTS START
  def handle_info({:collector_event, :collection_started}, state) do
    new_state = state
    |> Map.put(:collector_status, :active)
    |> Map.put(:status, :active)
    {:noreply, [], new_state}
  end
  def handle_info({:collector_event, :collection_finished}, state) do
    new_state = state
    |> Map.put(:collector_status, :inactive)
    |> Map.put(:status, :inactive)
    {:noreply, [], new_state}
  end
  def handle_info({:collector_event, {:snapshot, server_id}}, state) when state.status == :active do
    new_pending_events = [server_id | state.pending_events]
    new_state = Map.put(state, :pending_events, new_pending_events)
    {:noreply, [server_id], new_state}
  end
  def handle_info({:collector_event, {:info, _server_id}}, state), do: {:noreply, [], state}
  ######## COLLECTOR EVENTS END
  def handle_info({:medusa_etl_results, results}, state) do
    servers_id = for {server_id, _result} <- results, do: server_id
    new_pending_events = state.pending_events -- servers_id

    new_state = Map.put(state, :pending_events, new_pending_events)
    {:noreply, [], new_state}
  end

  def handle_info(_msg, state), do: {:noreply, [], state}
end
