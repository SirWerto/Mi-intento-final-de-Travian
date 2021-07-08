defmodule Collector.Plubio do
  use GenServer

  defstruct tsup: :nil, urls_wait: [], urls_doing: [], urls_done: %{}, subscriptors: []


  def start_link() do
    GenServer.start_link(__MODULE__, [], name: Collector.Plubio)
  end

  @impl true
  def init([]) do
    send(self(), :start_suptask)
    {:ok, %__MODULE__{}}
  end


  @impl true
  def handle_info(:start_suptask, state) do
    case Task.Supervisor.start_link() do
      {:ok, tsup} -> {:noreply, %{state | tsup: tsup}}
      {:error, error} -> {:stop, error, state}
    end
  end

  @impl true
  def handle_info(_message, state) do
    {:noreply, state}
  end


end
