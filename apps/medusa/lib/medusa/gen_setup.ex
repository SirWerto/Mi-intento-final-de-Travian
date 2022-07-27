defmodule Medusa.GenSetUp do
  use GenServer

  require Logger

  @enforce_keys [:n_consumers, :model_dir, :root_folder]
  defstruct [:n_consumers, :model_dir, :root_folder, consumer_sups: %{}, n_active: 0]


  @type t :: %__MODULE__{
    n_consumers: pos_integer(),
    consumer_sups: %{pid() => reference()},
    n_active: non_neg_integer()
  }


  @sub_options [
    to: Medusa.GenProducer,
    min_demand: 1,
    max_demand: 3
  ]

  @spec notify_ready(pid :: pid()) :: :ok
  def notify_ready(pid), do: GenServer.cast(Medusa.GenSetUp, {:consumer_ready, pid})


  @spec start_link(n_consumers :: pos_integer(), model_dir :: String.t(), root_folder :: String.t()) :: GenServer.on_start()
  def start_link(n_consumers, model_dir, root_folder) do
    GenServer.start_link(__MODULE__, [n_consumers, model_dir, root_folder], name: __MODULE__)
  end


  def init([n_consumers, model_dir, root_folder]) do
    state = %__MODULE__{n_consumers: n_consumers, model_dir: model_dir, root_folder: root_folder}
    {:ok, state, {:continue, :init_consumers_sup}}
  end

  def handle_continue(:init_consumers_sup, state = %__MODULE__{n_consumers: n}) do
    consumer_sups = for _i <- 0..n-1, into: %{}, do: start_consumer_sup(state.model_dir, state.root_folder)
    new_state = Map.put(state, :consumer_sups, consumer_sups)
    {:noreply, new_state}
  end


  def handle_cast({:consumer_ready, pid}, state = %__MODULE__{consumer_sups: cs}) do
    Logger.debug(%{msg: "Consumer ready requesting sync_sub", args: state})
    {:ok, _sub_tag} = GenStage.sync_subscribe(pid, @sub_options)
    # new_cs = Map.get_and_update(cs, pid, fn ref -> {ref, sub_tag} end)
    # new_state = Map.put(state, :consumer_sups, new_cs)
    {:noreply, state}
  end

  def handle_cast(_, state), do: {:noreply, state}

  def handle_info({:DOWN, _ref, :process, pid, reason}, state = %__MODULE__{consumer_sups: cs}) when is_map_key(cs, pid) do
    Logger.warning(%{msg: "ConsumerSup down", reason: reason, args: state})
    {new_pid, new_ref} = start_consumer_sup(state.model_dir, state.root_folder)
    new_cs = cs
    |> Map.delete(pid)
    |> Map.put(new_pid, new_ref)
    
    new_state = Map.put(state, :consumer_sups, new_cs)
    {:noreply, new_state}
  end
  def handle_info(_, state), do: {:noreply, state}

  defp start_consumer_sup(model_dir, root_folder) do
    {:ok, pid} = Medusa.DynSup.start_consumer_sup(model_dir, root_folder)
    ref = Process.monitor(pid)
    {pid, ref}
  end


end
