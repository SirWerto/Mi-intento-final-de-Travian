defmodule MedusaModelConsumer do
  use GenStage

  @moduledoc """
  Documentation for `MedusaModelConsumer`.
  """



  defstruct [:port, :port_ref, :model_dir, loaded?: false]

  @type t :: %__MODULE__{
    loaded?: boolean(),
    port: port() | nil,
    port_ref: reference() | nil,
    model_dir: binary() | nil}
  

  @spec start_link(medusa_app_dir :: binary(), subscriptions :: [pid()]) :: GenServer.on_start()
  def start_link(medusa_app_dir, subscriptions \\ []) do
    GenStage.start_link(__MODULE__, [medusa_app_dir, subscriptions])
  end


  @spec stop(pid :: pid(), reason :: any(), timeout :: pos_integer()) :: :ok
  def stop(pid, reason \\ :normal, timeout \\ 5000) do
    GenStage.stop(pid, reason, timeout)
  end


  @impl true
  def init([medusa_app_dir, []]) do
    send(self(), :load_model)
    {:consumer, %__MODULE__{loaded?: false, model_dir: medusa_app_dir}}
  end
  def init([medusa_app_dir, susbscriptions]) do
    send(self(), :load_model)
    {:consumer, %__MODULE__{loaded?: false, model_dir: medusa_app_dir}, subscribe_to: susbscriptions}
  end

  @impl true
  def handle_info(:load_model, state) do
    {port, ref} = MedusaModelConsumerPort.open_port(state.model_dir)
    true = MedusaModelConsumerPort.load_model(port)

    state = Map.put(state, :port, port)
    |> Map.put(:port_ref, ref)

    {:noreply, [], state}
  end

  def handle_info({port, {:data, "\"loaded\""}}, state = %__MODULE__{port: port}) do
    IO.puts("loaded")
    {:noreply, [], state}
  end

  def handle_info({port, {:data, "\"not loaded\""}}, state = %__MODULE__{port: port}) do
    IO.puts("not loaded")
    {:noreply, [], state}
  end

  def handle_info(msg, state) do
    IO.puts("not matched")
    IO.inspect(msg)
    IO.inspect(state)
    {:noreply, [], state}
  end





end
