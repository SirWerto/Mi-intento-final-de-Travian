defmodule Medusa do
  @moduledoc """
  `Medusa` is the application which holds the pipeline for making predictions.
  """

  @doc """
  Send players_id throught the pipeline for being evaluated. The result will be stored in a PredictonBank tables.
  """
  @spec eval_players(players_id :: [Medusa.Types.player_id()]) :: :ok
  def eval_players(players_id) do
    Medusa.Producer.eval_players(players_id)
  end

end
