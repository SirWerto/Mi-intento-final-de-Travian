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
    send(self(), :init)
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

    Logger.debug(%{
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

    Logger.error(%{
      msg: "Collector.GenWorker down, tries: #{counter}",
      type_collection: type,
      reason: reason,
      server_id: server_id
    })

    Logger.info(%{
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

  # @impl true
  # def handle_info(:collect, state) do
  #   Logger.info("Collection started")

  #   case handle_collection() do
  #     {:ok, monitor_pids} ->
  #       active_p = Map.merge(state.active_p, monitor_pids)
  #       collection_hour = Application.fetch_env!(:collector, :collection_hour)
  #       wait_time = Collector.Utils.time_until_collection(collection_hour)
  #       tref = :erlang.send_after(wait_time, self(), :collect)

  #       new_state =
  #         Map.put(state, :active_p, active_p)
  #         |> Map.put(:tref, tref)

  #       {:noreply, new_state}

  #     {:error, reason} ->
  #       Logger.info("(GenCollector)Unable to collect: " <> Kernel.inspect(reason))
  #       tref = :erlang.send_after(@time_between_tries, self(), :collect)
  #       state = Map.put(state, :tref, tref)
  #       {:noreply, state}
  #   end
  # end

  # def handle_info({:DOWN, _ref, :process, pid, :normal}, state) do
  #   case Map.has_key?(state.active_p, pid) do
  #     true -> {:noreply, handle_monitor_normal(state, pid)}
  #     false -> {:noreply, state}
  #   end
  # end

  # def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
  #   case Map.has_key?(state.active_p, pid) do
  #     true -> {:noreply, handle_monitor_nonormal(state, pid, reason)}
  #     false -> {:noreply, state}
  #   end
  # end

  # def handle_info(_msg, state), do: {:noreply, state}

  # defp handle_monitor_normal(state, pid) do
  #   active_p = Map.delete(state.active_p, pid)
  #   state = Map.put(state, :active_p, active_p)
  #   state
  # end

  # defp handle_monitor_nonormal(state, pid, reason) do
  #   {_ref, server_id, tries, type} = Map.get(state.active_p, pid)

  #   Logger.notice(
  #     "Unable to get #{inspect(type)} server: #{server_id} reason: #{inspect(reason)}"
  #   )

  #   case tries do
  #     @max_tries ->
  #       Logger.notice("Unable to launch #{inspect(type)} server: #{server_id} reason: @max_tries")
  #       active_p = Map.delete(state.active_p, pid)
  #       state = Map.put(state, :active_p, active_p)
  #       state

  #     _ ->
  #       case start_one_worker(server_id, type) do
  #         {:ok, {new_pid, new_ref, _server_id, _type}} ->
  #           Logger.notice("Launched #{inspect(type)} server: #{server_id}")

  #           active_p =
  #             state.active_p
  #             |> Map.delete(pid)
  #             |> Map.put(new_pid, {new_ref, server_id, tries + 1, type})

  #           state = Map.put(state, :active_p, active_p)
  #           state

  #         {:error, reason} ->
  #           Logger.notice(
  #             "Unable to launch #{inspect(type)} server: #{server_id} reason: #{inspect(reason)}"
  #           )

  #           active_p = Map.delete(state.active_p, pid)
  #           state = Map.put(state, :active_p, active_p)
  #           state
  #       end
  #   end
  # end

  # @spec handle_collection() :: {:ok, %{pid() => any()}} | {:error, any()}
  # defp handle_collection() do
  #   case :travianmap.get_urls() do
  #     {:error, reason} ->
  #       {:error, reason}

  #     {:ok, urls} ->
  #       process = Enum.flat_map(urls, &start_worker/1)

  #       process
  #       |> Enum.filter(&(&1 == :error))
  #       |> Enum.map(fn {:error, {server_id, type, reason}} ->
  #         Logger.notice(
  #           "Unable to launch #{inspect(type)} server: #{server_id} reason: #{reason}"
  #         )
  #       end)

  #       monitor_pids =
  #         for {:ok, {pid, ref, server_id, type}} <- process,
  #             into: %{},
  #             do: {pid, {ref, server_id, 0, type}}

  #       {:ok, monitor_pids}
  #   end
  # end

  # @spec start_worker(server_id :: TTypes.server_id()) :: [
  #         :ok | {:ignore, binary()} | {:error, any()}
  #       ]
  # defp start_worker(server_id) do
  #   [
  #     Collector.CollectorSupervisor.start_worker_info(server_id),
  #     Collector.CollectorSupervisor.start_worker_snapshot(server_id)
  #   ]
  # end

  # defp start_one_worker(server_id, :info),
  #   do: Collector.CollectorSupervisor.start_worker_info(server_id)

  # defp start_one_worker(server_id, :snapshot),
  #   do: Collector.CollectorSupervisor.start_worker_snapshot(server_id)
end
