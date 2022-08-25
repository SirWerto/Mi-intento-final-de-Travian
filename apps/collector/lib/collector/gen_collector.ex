defmodule Collector.GenCollector do
  use GenServer
  require Logger

  defstruct [:tref, active: false, active_p: %{}, subscriptions: []]

  @spec start_link() :: GenServer.on_start()
  def start_link(), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @spec collect() :: :ok
  def collect() do
    send(__MODULE__, :collect)
    :ok
  end

  @spec subscribe() :: {:ok, reference()} | {:error, any()}
  def subscribe() do
    try do
      :ok = GenServer.call(__MODULE__, :subscribe)
      ref = Process.monitor(Collector.GenCollector)
      {:ok, ref}
    rescue
      e in RuntimeError -> {:error, e}
    end
  end

  @impl true
  def init([]) do
    {:ok, %__MODULE__{}, {:continue, []}}
  end

  @impl true
  def handle_continue(_continue, state) do
    collection_hour = Application.fetch_env!(:collector, :collection_hour)
    wait_time = Collector.Utils.time_until_collection(collection_hour)
    tref = :erlang.send_after(wait_time, self(), :collect)
    state = Map.put(state, :tref, tref)
    {:noreply, state}
  end

  @impl true
  def handle_call(:subscribe, {pid, _}, state = %__MODULE__{subscriptions: subs}) do
    new_subs = [pid | subs]
    new_state = Map.put(state, :subscriptions, new_subs)
    {:reply, :ok, new_state}
  end

  def handle_call(_msg, _from, state), do: {:noreply, state}

  @impl true
  def handle_cast({type_c, server_id, pid}, state = %__MODULE__{active_p: active_p, active: true})
      when is_map_key(active_p, pid) do
    event = {:collector_event, {type_c, server_id}}
    Enum.each(state.subscriptions, &send(&1, event))
    {:noreply, state}
  end

  def handle_cast(_msg, state), do: {:noreply, state}

  @impl true
  def handle_info(
        {:DOWN, _ref, :process, pid, :normal},
        state = %__MODULE__{active_p: ap, active: true}
      )
      when is_map_key(ap, pid) and map_size(ap) == 1 do
    new_state =
      state
      |> Map.put(:active_p, %{})
      |> Map.put(:active, false)

    Enum.each(state.subscriptions, &send(&1, {:collector_event, :collection_finished}))
    Logger.info(%{msg: "Collection finished"})
    {:noreply, new_state}
  end

  def handle_info(
        {:DOWN, _ref, :process, pid, :normal},
        state = %__MODULE__{active_p: ap, active: true}
      )
      when is_map_key(ap, pid) do
    {{type, _ref, server_id, _counter}, new_ap} = Map.pop!(ap, pid)

    Logger.info(%{
      msg: "Collector.GenWorker finished",
      type_collection: type,
      server_id: server_id
    })

    new_state = Map.put(state, :active_p, new_ap)

    {:noreply, new_state}
  end

  def handle_info(
        {:DOWN, _ref, :process, pid, reason},
        state = %__MODULE__{active_p: ap, active: true}
      )
      when is_map_key(ap, pid) do
    {{type, _ref, server_id, counter}, new_ap} = Map.pop!(ap, pid)

    Logger.warning(%{
      msg: "Collector.GenWorker down, tries: #{counter}",
      type_collection: type,
      reason: reason,
      server_id: server_id
    })

    case {new_ap, start_child(type, server_id)} do
      {new_ap, {:ok, {pid, ref}}} ->
        new_ap = Map.put(new_ap, pid, {type, ref, server_id, counter + 1})
        new_state = Map.put(state, :active_p, new_ap)
        {:noreply, new_state}

      {new_ap, {:error, reason}} when map_size(new_ap) == 0 ->
        Logger.warning(%{
          msg: "Unable to start Collector.GenWorker",
          type_collection: type,
          reason: reason,
          server_id: server_id
        })

        new_state =
          state
          |> Map.put(:active_p, %{})
          |> Map.put(:active, false)

        Enum.each(state.subscriptions, &send(&1, {:collector_event, :collection_finished}))
        Logger.info(%{msg: "Collection finished"})
        {:noreply, new_state}

      {new_ap, {:error, reason}} ->
        Logger.warning(%{
          msg: "Unable to start Collector.GenWorker",
          type_collection: type,
          reason: reason,
          server_id: server_id
        })

        new_state = Map.put(state, :active_p, new_ap)
        {:noreply, new_state}
    end
  end

  def handle_info(:collect, state = %__MODULE__{active: false}) do
    Logger.info(%{msg: "Collection started"})

    case :travianmap.get_urls() do
      {:error, reason} ->
        Logger.warning(%{msg: "Unable to start the colletion", reason: reason})
        tref = :erlang.send_after(3_000, self(), :collect)
        new_state = Map.put(state, :tref, tref)
        {:noreply, new_state}

      {:ok, urls} ->
        {childs, errors} =
          urls
          |> Enum.flat_map(
            &[
              {Collector.Supervisor.Snapshot.start_child(&1), &1, :snapshot},
              {Collector.Supervisor.Metadata.start_child(&1), &1, :metadata}
            ]
          )
          |> Enum.split_with(fn {{atom, _}, _, _} -> atom == :ok end)

        Enum.each(
          errors,
          &Logger.warning(%{msg: "Unable to start Collector.GenWorker", reason: elem(&1, 1)})
        )

        ap =
          for {{:ok, {pid, ref}}, server_id, type_c} <- childs,
              into: %{},
              do: {pid, {type_c, ref, server_id, 0}}

        collection_hour = Application.fetch_env!(:collector, :collection_hour)
        wait_time = Collector.Utils.time_until_collection(collection_hour)
        tref = :erlang.send_after(wait_time, self(), :collect)

        new_state =
          state
          |> Map.put(:active_p, ap)
          |> Map.put(:active, true)
          |> Map.put(:tref, tref)

        Enum.each(state.subscriptions, &send(&1, {:collector_event, :collection_started}))
        {:noreply, new_state}
    end
  end

  def handle_info(_msg, state), do: {:noreply, state}

  @spec start_child(:snapshot | :metadata, TTypes.server_id()) ::
          {:ok, {pid(), reference()}} | {:error, any()}
  defp start_child(:snapshot, server_id), do: Collector.Supervisor.Snapshot.start_child(server_id)
  defp start_child(:metadata, server_id), do: Collector.Supervisor.Metadata.start_child(server_id)
end
