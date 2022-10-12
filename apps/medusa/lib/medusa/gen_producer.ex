defmodule Medusa.GenProducer do
  use GenStage

  require Logger

  defstruct [:collector_ref, collector_status: :inactive, status: :inactive, subs: [], pending_events: []]


  @type t :: %__MODULE__{
    collector_status: :active | :inactive,
    status: :active | :inactive,
    collector_ref: nil | reference(),
    pending_events: [TTypes.server_id],
    subs: list(pid())
  }

  @spec start_link() :: GenServer.on_start()
  def start_link() do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end


  @spec subscribe() :: reference()
  def subscribe() do
    :ok = GenServer.call(__MODULE__, {:subscribe, self()})
    Process.monitor(__MODULE__)
  end

  @impl true
  def init([]) do
    state = %__MODULE__{}
    send(self(), :init)
    {:producer, state}
  end

  @impl true
  def handle_demand(_demand, state), do: {:noreply, [], state}

  @impl true
  def handle_call({:subscribe, pid}, _from, state) do
    case pid in state.subs do
      true -> {:reply, :ok, [], state}
      false ->
	new_state = Map.put(state, :subs, [pid | state.subs])
	{:reply, :ok, [], new_state}
    end
  end
  def handle_call(_msg, _from, state), do: {:noreply, state}




  @impl true
  def handle_cast({:medusa_etl_result, server_id, result}, state = %__MODULE__{status: :active, collector_status: :inactive, pending_events: [server_id]}) do
	new_state = state
	|> Map.put(:pending_events, [])
	|> Map.put(:status, :inactive)

	forward_predictions(server_id, result, state.subs)
	Enum.each(state.subs, fn x -> send(x, {:medusa_event, :prediction_finished}) end)
	Logger.info(%{msg: "Medusa.GenProducer inactive"})
	{:noreply, [], new_state}
  end
  def handle_cast({:medusa_etl_result, server_id, result}, state = %__MODULE__{status: :active}) do
    forward_predictions(server_id, result, state.subs)
    new_pending_events  = state.pending_events -- [server_id]
    new_state = Map.put(state, :pending_events, new_pending_events)
    {:noreply, [], new_state}
  end

  def handle_cast(_msg, state), do: {:noreply, [], state}


  @impl true
  def handle_info(:init, state) do
    ref = Collector.subscribe()
    Logger.debug(%{msg: "Medusa.GenProducer subscribed to Collector"})
    new_state = Map.put(state, :collector_ref, ref)
    {:noreply, [], new_state}
  end
  def handle_info({:DOWN, ref, :process, _pid, reason}, state = %{collector_ref: ref}) do
    Logger.warning(%{msg: "Collector down, relaunching Medusa, events running will be lost", reason: reason, args: state})
    {:stop, :normal, state}
  end
  ######## COLLECTOR EVENTS START
  def handle_info({:collector_event, :collection_started}, state) do
    Logger.info(%{msg: "Medusa.GenProducer active"})
    new_state = state
    |> Map.put(:collector_status, :active)
    |> Map.put(:status, :active)
    Enum.each(state.subs, fn x -> send(x, {:medusa_event, :prediction_started}) end)
    {:noreply, [], new_state}
  end
  def handle_info({:collector_event, :collection_finished}, state) do
    case state.pending_events do
      [] ->
	Logger.info(%{msg: "Medusa.GenProducer inactive"})
	new_state = state
	|> Map.put(:collector_status, :inactive)
	|> Map.put(:status, :inactive)
	Enum.each(state.subs, fn x -> send(x, {:medusa_event, :prediction_finished}) end)
	{:noreply, [], new_state}
      _ ->
	new_state = state
	|> Map.put(:collector_status, :inactive)
	{:noreply, [], new_state}
    end
  end

  def handle_info({:collector_event, {:snapshot_collected, server_id}}, state) when state.status == :active do
    Logger.debug(%{msg: "Medusa.GenProducer snapshot event received", server_id: server_id})
    new_pending_events = [server_id | state.pending_events]
    new_state = Map.put(state, :pending_events, new_pending_events)
    {:noreply, [server_id], new_state}
  end
  def handle_info({:collector_event, {other_event, server_id}}, state) do
    Logger.debug(%{msg: "Medusa.GenProducer other event received", server_id: server_id, event: other_event})
    {:noreply, [], state}
  end
  ######## COLLECTOR EVENTS END
  def handle_info(_msg, state), do: {:noreply, [], state}

  defp forward_predictions(server_id, :ok, subs) do
    Enum.each(subs, fn x -> send(x, {:medusa_event, {:prediction_done, server_id}}) end)
    Logger.debug(%{msg: "Medusa.GenProducer event forwarded", server_id: server_id, subs: subs})
  end

  defp forward_predictions(server_id, {:error, _reason}, subs) do
    Enum.each(subs, fn x -> send(x, {:medusa_event, {:prediction_failed, server_id}}) end)
    Logger.debug(%{msg: "Medusa.GenProducer event forwarded", server_id: server_id, subs: subs})
  end
end
