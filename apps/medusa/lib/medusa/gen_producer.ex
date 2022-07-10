defmodule Medusa.GenProducer do
  use GenStage

  require Logger

  defstruct [:model_dir, :root_folder, :n_consumers, collector_status: :inactive, status: :inactive, consumers: %{}, subs: %{}, n_active: 0, collector_ref: nil, pending_events: []]


  @type t :: %__MODULE__{
    model_dir: String.t(),
    root_folder: String.t(),
    collector_status: :active | :inactive,
    status: :active | :inactive,
    n_consumers: pos_integer(),
    n_active: integer(),
    collector_ref: nil | reference(),
    pending_events: [TTypes.server_id],
    subs: map(),
    consumers: map()
  }

  @spec start_link(model_dir :: String.t(), root_folder :: String.t(), n_consumers :: pos_integer())
  :: GenServer.on_start()
  def start_link(model_dir, root_folder, n_consumers) do
    GenStage.start_link(__MODULE__, [model_dir, root_folder, n_consumers], name: __MODULE__)
  end

  # def subscribe(), do: ok
  # def unsubscribe(), do: ok

  @impl true
  def init([model_dir, root_folder, n_consumers]) do
    state = %__MODULE__{
      model_dir: model_dir,
      root_folder: root_folder,
      n_consumers: n_consumers
    }
    send(self(), :init_consumers)
    {:producer, state}
  end

  @impl true
  def handle_subscribe(:consumer, _options, {pid, _tag}, state) do
    ref = Process.monitor(pid)
    new_consumers = Map.put(state.consumers, pid, ref)

    new_state = state
    |> Map.put(:consumers, new_consumers)
    |> Map.put(:n_active, state.n_active + 1)

    {:automatic, new_state}
  end

  @impl true
  def handle_demand(_demand, state), do: {:noreply, [], state}

  @impl true
  def handle_info(:init_consumers, state) do
    with Medusa.

    Enum.each(0..state.n_consumers-1, fn _ -> Medusa.DynSup.start_child(state.model_dir) end)
    case Collector.subscribe() do
      {:ok, ref} ->
	new_state = Map.put(state, :collector_ref, ref)
	{:noreply, [], new_state}
      {:error, reason} ->
	Logger.warning(%{msg: "Medusa.GenProducer unable to subscribe to Collecotor", reason: reason, args: state})
	{:stop, :normal, state}
    end
  end
  def handle_info({:DOWN, _ref, :process, pid, reason}, state = %{consumers: consumers}) when is_map_key(consumers, pid) do
    Logger.notice(%{msg: "Medusa.GenConsumer down, relaunching a Medusa.ConsumerSup", reason: reason, args: state.model_dir})
    Medusa.DynSup.start_child(state.model_dir)
    new_consumers = Map.delete(consumers, pid)

    new_state = state
    |> Map.put(:consumers, new_consumers)
    |> Map.put(:n_active, state.active - 1)
    {:noreply, [], new_state}
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
