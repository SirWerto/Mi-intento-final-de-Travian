defmodule Medusa do
  @moduledoc """
  `Medusa` is the application which holds the pipeline for making predictions.
  """

  @spec subscribe(spid :: pid()) :: {:ok, :subscribed} | {:error, any()}
  def subscribe(spid) do
    Medusa.Brain.subscribe(spid)
  end


  @spec subscribers() :: {:ok, [pid()]} | {:error, any()}
  def subscribers() do
    Medusa.Brain.subscribers()
  end


  @spec eval_players(players_id :: [String.t()]) :: :ok
  def eval_players(players_id) do
    Medusa.Brain.new_players_id(players_id)
  end

  @spec evaluated_players() :: {:ok, %{String.t() => Medusa.Brain.condition()}} | {:error, any()}
  def evaluated_players() do
    Medusa.Brain.evaluated_players()
  end

end
