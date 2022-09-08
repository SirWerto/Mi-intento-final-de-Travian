defmodule MedusaMetrics do
  @moduledoc """
  Documentation for `MedusaMetrics`.
  """

  @metrics_options {"medusa_metrics", ".bert"}
  @failed_options {"medusa_failed", ".c6bert"}

  @type model :: :player_n | :player_1
  @type failed :: {TTypes.server_id(), TTypes.player_id(), model()}


  @spec metrics_options() :: {binary(), binary()}
  def metrics_options(), do: @metrics_options

  @spec metrics_to_format(metrics :: map()) :: binary()
  def metrics_to_format(metrics),
    do: :erlang.term_to_binary(metrics, [:deterministic])

  @spec metrics_from_format(encoded_metrics :: binary()) :: map()
  def metrics_from_format(encoded_metrics), do: :erlang.binary_to_term(encoded_metrics)


  @spec failed_options() :: {binary(), binary()}
  def failed_options(), do: @failed_options

  @spec failed_to_format(failed :: {TTypes.server_id(), TTypes.player_id()}) :: binary()
  def failed_to_format(failed),
    do: :erlang.term_to_binary(failed, [:deterministic])

  @spec failed_from_format(encoded_failed :: binary()) :: {TTypes.server_id(), TTypes.player_id()}
  def failed_from_format(encoded_failed), do: :erlang.binary_to_term(encoded_failed)

  @spec etl(root_folder :: binary(), server_id :: TTypes.server_id(), new_date :: Date.t(), old_date :: Date.t()) :: {:ok, {map(), [failed()]}} | {:error, reason}
  def etl(root_folder, server_id, new_date, old_date) do
    with (
      {:step_1, {:ok, {^new_date, new_encoded_predictions}}} <- {:step_1, Storage.open(root_folder, server_id, Medusa.predictions_options(), new_date)}
      {:step_2, {:ok, {^old_date, old_encoded_predictions}}} <- {:step_2, Storage.open(root_folder, server_id, Medusa.predictions_options(), old_date)}
    ) do
      new = for pred <- Medusa.predictions_from_format(new_encoded_predictions), do: {pred, :new}
      old = for pred <- Medusa.predictions_from_format(old_encoded_predictions), do: {pred, :old}

      common_predicted = new ++ old
      |> Enum.group_by(fn {x, _} -> x.player_id end)
      |> Enum.filter(fn {_k, x} -> x != 2 end)

      failed = common_predicted
      |> Enum.map(fn {_k, [x, y]} -> eval_pred(x, y) end)
      |> Enum.filter(fn x -> x == nil end)

      metrics = get_metrics(common_predicted, failed)
      {:ok, {metrics, failed}}
    else
      {:step_1, {:error, reason}} -> {:error, {:error_new_file, reason}}
      {:step_2, {:error, reason}} -> {:error, {:error_old_file, reason}}
    end
  end

  defp eval_pred(x = {_, :old}, y = {_, :new}), do: eval_pred(y, x)
  defp eval_pred({x, :new}, {y, :old}) when x.inactive_in_current == y.inactive_in_future, do: nil
  defp eval_pred({x, :new}, {_y, :old}) do
    {x.server_id, x.player_id, x.model}
  end

  defp get_metrics(common_predicted, failed) do
    %{
      total_players: Enum.count(common_predicted),
      failed_players: Enum.count(failed),
      total_model_player_1: Enum.count(common_predicted),
      failed_model_player_1: 1,
      total_model_player_n: 0,
      failed_model_player_n: 0,
    }
  end


end
