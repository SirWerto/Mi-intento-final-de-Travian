defmodule MedusaMetrics do
  @moduledoc """
  Documentation for `MedusaMetrics`.
  """

  @metrics_options {"medusa_metrics", ".bert"}
  @failed_options {"medusa_failed", ".c6bert"}

  @type failed :: {TTypes.server_id(), TTypes.player_id(), Medusa.model()}


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

  @spec et(root_folder :: binary(), server_id :: TTypes.server_id(), target_date :: Date.t(), old_date :: Date.t()) :: {:ok, {map(), [failed()]}} | {:error, any()}
  def et(root_folder, server_id, target_date, old_date) do
    with(
      {:step_1, {:ok, {^target_date, new_encoded_predictions}}} <- {:step_1, Storage.open(root_folder, server_id, Medusa.predictions_options(), target_date)},
      {:step_2, {:ok, {^old_date, old_encoded_predictions}}} <- {:step_2, Storage.open(root_folder, server_id, Medusa.predictions_options(), old_date)}
    ) do

      new = Medusa.predictions_from_format(new_encoded_predictions)
      old = Medusa.predictions_from_format(old_encoded_predictions)

      players_new = for pred <- new, do: pred.player_id
      players_old = for pred <- old, do: pred.player_id

      players_common = :sets.to_list(:sets.intersection(:sets.from_list(players_new), :sets.from_list(players_old)))

      new_common = Enum.filter(new, fn x -> x.player_id in players_common end) |> Enum.sort_by(fn x-> x.player_id end)
      old_common = Enum.filter(old, fn x -> x.player_id in players_common end) |> Enum.sort_by(fn x-> x.player_id end)

      common = Enum.zip(new_common, old_common)


      init_acc = {
	[],
	%MedusaMetrics.Metrics{
	  target_date: target_date,
	  old_date: old_date,
	  total_players: 0,
	  failed_players: 0,
	  models: %{}},
	target_date,
	old_date
      }
      
      {failed, metrics, _target_date, _old_date} = Enum.reduce(common, init_acc, fn x, acc -> aggregation(x, acc) end)
      {:ok, {metrics, failed}}
      else
	{:step_1, error} -> {:error, {"failed while reading target_file", error}}
	{:step_2, error} -> {:error, {"failed while reading old_file", error}}
    end
  end

  defp aggregation({new, old}, {failed, metrics, target_date, old_date}) when new.inactive_in_current == old.inactive_in_future do
    new_models = Map.update(metrics.models, old.model,
      %MedusaMetrics.Models{model: old.model, total_players: 1, failed_players: 0},
      fn x -> Map.put(x, :total_players, x.total_players + 1) end)
    new_metrics = metrics
    |> Map.put(:models, new_models)
    |> Map.put(:total_players, metrics.total_players + 1)
    {failed, new_metrics, target_date, old_date}
  end

  defp aggregation({new, old}, {failed, metrics, target_date, old_date}) when new.inactive_in_current != old.inactive_in_future do
    new_models = Map.update(metrics.models, old.model,
      %MedusaMetrics.Models{model: old.model, total_players: 1, failed_players: 1},
      fn x -> %MedusaMetrics.Models{model: x.model, total_players: x.total_players + 1, failed_players: x.failed_players + 1} end)
    new_metrics = metrics
    |> Map.put(:models, new_models)
    |> Map.put(:total_players, metrics.total_players + 1)
    |> Map.put(:failed_players, metrics.failed_players + 1)
    new_failed = [
      %MedusaMetrics.Failed{server_id: new.server_id, player_id: new.player_id, model: old.model, target_date: target_date, old_date: old_date, expected: old.inactive_in_future, result: new.inactive_in_current}
      | failed]
    {new_failed, new_metrics, target_date, old_date}
  end

end
