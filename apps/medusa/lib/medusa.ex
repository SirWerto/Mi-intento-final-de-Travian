defmodule Medusa do
  @moduledoc """
  `Medusa` is the application which holds the pipeline for making predictions.
  """

  @type player_status :: :active, :inactive, :future_inactive

  @type model :: :player_n | :player_1

  @predictions_options {"medusa_predictions", ".c6bert"}

  @spec predictions_options() :: {binary(), binary()}
  def predictions_options(), do: @predictions_options

  @spec subscribe() :: reference()
  def subscribe(), do: Medusa.GenProducer.subscribe


  @spec etl(root_folder :: binary(), port :: pid(), server_id :: TTypes.server_id(), target_date :: Date.t()) :: {:ok, [map()]} | {:error, any()}
  def etl(root_folder, port, server_id, target_date \\ Date.utc_today()) when is_binary(root_folder) and is_pid(port) and is_binary(server_id) do
    Medusa.ETL.apply(root_folder, port, server_id, target_date)
  end


  @spec predictions_to_format(predictions :: [map()]) :: binary()
  def predictions_to_format(predictions),
    do: :erlang.term_to_binary(predictions, [:compressed, :deterministic])

  @spec predictions_from_format(encoded_predictions :: binary()) :: [map()]
  def predictions_from_format(encoded_predictions), do: :erlang.binary_to_term(encoded_predictions)
  

end
