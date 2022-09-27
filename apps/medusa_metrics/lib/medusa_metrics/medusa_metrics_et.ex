defmodule MedusaMetrics.ET do

  @spec apply(root_folder :: binary(), server_id :: TTypes.server_id(), target_date :: Date.t(), old_date :: Date.t()) :: {:ok, {MedusaMetrics.Metrics.t(), [MedusaMetrics.Failed.t()]}} | {:error, any()}
  def apply(root_folder, server_id, target_date, old_date) do
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
	  models: %{},
	  square: %MedusaMetrics.Square{t_p: 0, t_n: 0, f_p: 0, f_n: 0}
	},
	target_date,
	old_date
      }
      
      {failed, metrics, _target_date, _old_date} = Enum.reduce(common, init_acc, fn x, acc -> aggregation(x, acc) end)
      {:ok, {compute_players(metrics), failed}}
      else
	{:step_1, error} -> {:error, {"failed while reading target_file", error}}
	{:step_2, error} -> {:error, {"failed while reading old_file", error}}
    end
  end



  defp aggregation({new, old}, {failed, metrics, target_date, old_date}) do
    new_models = update_models(metrics.models, old.model, new.inactive_in_current, old.inactive_in_future)
    new_square = MedusaMetrics.Square.update(metrics.square, new.inactive_in_current, old.inactive_in_future)
    new_metrics = metrics
    |> Map.put(:models, new_models)
    |> Map.put(:square, new_square)


    new_failed = compute_failed(failed, new, old, target_date, old_date)

    {new_failed, new_metrics, target_date, old_date}
  end

  defp update_models(models, model_name, inactive_in_current, inactive_in_future) when is_map_key(models, model_name) do
    Map.update!(models, model_name, fn x -> Map.put(x, :square, MedusaMetrics.Square.update(x.square, inactive_in_current, inactive_in_future)) end)
  end
  defp update_models(models, model_name, inactive_in_current, inactive_in_future) do
    new_model = %MedusaMetrics.Models{model: model_name,
				      total_players: 0,
				      failed_players: 0,
				      square: %MedusaMetrics.Square{t_p: 0, t_n: 0, f_p: 0, f_n: 0}}
    new_model = Map.put(new_model, :square, MedusaMetrics.Square.update(new_model.square, inactive_in_current, inactive_in_future))
    Map.put(models, model_name, new_model)
  end

  defp compute_players(metrics) do
    new_models = for {k, v} <- metrics.models, into: %{}, do: {k, compute_v(v)}

    metrics
    |> Map.put(:models, new_models)
    |> Map.put(:total_players, MedusaMetrics.Square.total_players(metrics.square))
    |> Map.put(:failed_players, MedusaMetrics.Square.failed_players(metrics.square))
  end

  defp compute_v(x) do
    x
    |> Map.put(:total_players, MedusaMetrics.Square.total_players(x.square))
    |> Map.put(:failed_players, MedusaMetrics.Square.failed_players(x.square))
  end

  defp compute_failed(failed, new, old, target_date, old_date) do
    case {new.inactive_in_current, old.inactive_in_future} do
      {x, x} -> failed
      {_x, _y} -> 
	new_failed = [
	  %MedusaMetrics.Failed{server_id: new.server_id, player_id: new.player_id, model: old.model, target_date: target_date, old_date: old_date, expected: old.inactive_in_future, result: new.inactive_in_current}
	  | failed]
    end
  end
  end
