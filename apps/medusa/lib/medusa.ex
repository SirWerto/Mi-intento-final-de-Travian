defmodule Medusa do
  @moduledoc """
  `Medusa` is the application which holds the pipeline for making predictions.
  """

  @spec subscribe(spid :: pid()) :: {:ok, :subscribed} | {:error, any()}
  def subscribe(spid) do
    Medusa.Brain.subscribe(spid)
  end

  @spec unsubscribe(spid :: pid()) :: {:ok, :unsubscribed} | {:error, any()}
  def unsubscribe(spid) do
    Medusa.Brain.unsubscribe(spid)
  end


  @spec subscribers() :: {:ok, [pid()]} | {:error, any()}
  def subscribers() do
    Medusa.Brain.subscribers()
  end


  @spec send_players(players_id :: [String.t()]) :: :ok
  def send_players(players_id) do
    Medusa.Brain.send_players(players_id)
  end

end
