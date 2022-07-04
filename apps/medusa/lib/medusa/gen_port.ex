defmodule Medusa.GenPort do
  use GenServer
  require Logger

  defstruct [:model_dir, port: nil, ref: nil, setup: false]


  @type t :: %__MODULE__{
    model_dir: String.t(),
    setup: boolean(),
    port: pid(),
    ref: reference()
  }

  @spec predict(port :: pid(), data :: [Medusa.Pipeline.Step2.t()]) :: {:ok, [Medusa.Port.t()]} | {:error, any()}
  def predict(port, data) do
    try do
      GenServer.call(port, {:predict, data}, 15_000)
    rescue
      e in RuntimeError -> {:error, e}
    end
  end


  @spec start_link(model_dir :: String.t()) :: GenServer.on_start()
  def start_link(model_dir), do: GenServer.start_link(__MODULE__, model_dir)


  @impl true
  def init(model_dir) do
    state = %__MODULE__{model_dir: model_dir}
    {:ok, state, {:continue, :load_model}}
  end

  @impl true
  def handle_continue(:load_model, state) do
    {port, ref} = Medusa.Port.open(state.model_dir)
    new_state = state
    |> Map.put(:port, port)
    |> Map.put(:ref, ref)
    |> Map.put(:setup, true)
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:predict, data}, _, state = %{setup: true}) do
    predictions = Medusa.Port.predict!(state.port, data)
    {:reply, predictions}
  end
  def handle_call(_, _, state), do: {:noreply, state}

  @impl true
  def handle_info({:DOWN, ref, :port, port, reason}, state = %{ref: ref, port: port}) do
    Logger.error(%{msg: "Python model down", reason: reason, state: state})
    {:stop, {"Python model down", reason}, state}
  end
  def handle_info(_, state), do: {:noreply, state}

  @impl true
  def handle_cast(_, state), do: {:noreply, state}

  @impl true
  def terminate(_, state) do
    Medusa.Port.close(state.port, state.ref)
  end



end
