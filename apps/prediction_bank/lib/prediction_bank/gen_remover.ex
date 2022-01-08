defmodule PredictionBank.GenRemover do
  use GenServer
  require Logger

  @milliseconds_in_day 24*60*60*1000

  def start_link([]), do: GenServer.start_link(__MODULE__, [], [])

  @impl true
  def init([]) do
    send(self(), :init)
    {:ok, []}
  end


  @impl true
  def handle_call(_msg, _from, state), do: {:noreply, state}

  @impl true
  def handle_cast(_msg, state), do: {:noreply, state}


  @impl true
  def handle_info(:init, _state) do
    removing_hour = Application.fetch_env!(:prediction_bank, :remove_hour)
    wait_time = time_until_removing(removing_hour) 
    tref = :erlang.send_after(wait_time, self(), :remove)
    {:noreply, tref}
  end

  def handle_info(:remove, _state) do
    Logger.debug("removing old players")
    PredictionBank.remove_old_players()
    Logger.debug("removed old players")
    removing_hour = Application.fetch_env!(:prediction_bank, :remove_hour)
    wait_time = time_until_removing(removing_hour) 
    tref = :erlang.send_after(wait_time, self(), :remove)
    {:noreply, tref}
  end


  defp time_until_removing(removing_hour), do: time_until_removing(removing_hour, Time.utc_now())

  defp time_until_removing(rh, rh), do: 0
  defp time_until_removing(rh, now) when rh > now, do: Time.diff(rh, now, :millisecond)
  defp time_until_removing(rh, now), do: @milliseconds_in_day + Time.diff(rh, now, :millisecond)
end
