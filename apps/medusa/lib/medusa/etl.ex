defmodule Medusa.ETL do

  require Logger

  @n_snapshots 5
  @snapshot_options {"snapshot", ".c6bert"}
  @predictions_options {"medusa_predictions", ".c6bert"}

  @spec apply(root_folder :: binary(), port :: pid(), server_id :: TTypes.server_id(), target_date :: Date.t()) :: {:ok, [Satellite.MedusaTable.t()]} | {:error, any()}
  def apply(root_folder, port, server_id, target_date) do
    date_options = {Date.add(target_date, 1-@n_snapshots), target_date, :consecutive}
    with(
      Logger.debug(%{msg: "Medusa ETL step 1, open snapshots", args: server_id}),
      {:ok, encoded_snapshots = [{^target_date, encoded_lastest_snapshot} | _]} <- Storage.open(root_folder, server_id, @snapshot_options, date_options),
      Logger.debug(%{msg: "Medusa ETL step 2, prepare raw", args: server_id}),
      lastest_snapshot = Collector.snapshot_from_format(encoded_lastest_snapshot),
      {raw_players_id, prepared_raw} = prepare_raw(lastest_snapshot),
      Logger.debug(%{msg: "Medusa ETL step 3, apply pipeline and process", args: server_id}),
      snapshots =  Enum.map(encoded_snapshots, fn {d, v} -> {d, Collector.snapshot_from_format(v)} end), 
      {processed_players_id, prepared_processed} = Medusa.Pipeline.apply(snapshots) |> prepare_processed(),
      Logger.debug(%{msg: "Medusa ETL step 4, health check raw vs processed", args: server_id}),
      :ok <- health_check_players(raw_players_id, processed_players_id, :raw_vs_processed),
      Logger.debug(%{msg: "Medusa ETL step 5, apply predictions and process", args: server_id}),
      {:ok, predictions} <- Medusa.GenPort.predict(port, prepared_processed),
      {pred_players_id, prepared_predictions} = prepare_predictions(predictions),
      Logger.debug(%{msg: "Medusa ETL step 6, health check processed vs predictions", args: server_id}),
      :ok <- health_check_players(processed_players_id, pred_players_id, :processed_vs_predictions),
      Logger.debug(%{msg: "Medusa ETL step 7, enrich", args: server_id}),
      enriched_predictions = enrich_preds(prepared_raw, prepared_processed, prepared_predictions, target_date),
      Logger.debug(%{msg: "Medusa ETL step 8, store enrich", args: server_id}),
      encoded_predictions = Medusa.predictions_to_format(enriched_predictions),
      {:step_8, :ok} <- {:step_8, Storage.store(root_folder, server_id, @predictions_options, encoded_predictions, target_date)}

      # :ok <- Satellite.send_medusa_predictions(enriched_predictions)
    ) do
      Logger.info(%{msg: "Medusa ETL success", server_id: server_id})
      {:ok, enriched_predictions}
    else
      {:step_8, {:error, reason}} ->
	Logger.warning(%{msg: "Medusa ETL error", step: 8, reason: reason, server_id: server_id})
	{:error, reason}
      {:error, reason = {:unhealthy_data, _reason}} ->
	Logger.alert(%{msg: "Medusa ETL health check error", reason: reason, args: {server_id}})
        {:error, reason}
      {:error, reason} ->
	Logger.warning(%{msg: "Medusa ETL error", reason: reason, args: {server_id}})
        {:error, reason}
    end
  end

  @spec health_check_players(old :: [TTypes.player_id], new :: [TTypes.player_id], step :: atom()) :: :ok | {:error, {:unhealthy_data, any()}}
  defp health_check_players(old, new, step) do
    case old -- new do
      [] -> case new -- old do
	      [] -> :ok
	      generated_players -> {:error, {:unhealthy_data, {"players number increased in #{step}", generated_players}}}
	    end
      leaked_players -> {:error, {:unhealthy_data, {"players leaked in #{step}", leaked_players}}}
    end
  end




  @spec prepare_raw(lastest_snapshot :: [Collector.SnapshotRow.t()]) :: {[TTypes.player_id], [TTypes.enriched_row()]}
  defp prepare_raw(snapshot_rows) do
    snapshot_rows
    |> Enum.sort_by(fn x -> x.player_id end)
    |> Enum.dedup_by(fn x -> x.player_id end)
    |> Enum.map(fn x -> {x.player_id, x} end)
    |> Enum.unzip()

    #recent_filtered = Enum.sort(recent, &(&1.player_id >= &2.player_id)) |> Enum.dedup_by(&(&1.player_id))

  end


  @spec prepare_processed(processed :: [Medusa.Pipeline.Step2.t()]) :: {[TTypes.player_id()], [Medusa.Pipeline.Step2.t()]}
  defp prepare_processed(processed) do
    processed
    |> Enum.sort_by(fn x -> x.fe_struct.player_id end)
    |> Enum.map(fn x -> {x.fe_struct.player_id, x} end)
    |> Enum.unzip()
  end


  @spec prepare_predictions(predictions :: [Medusa.Port.t()]) :: {[TTypes.player_id()], [Medusa.Port.t()]}
  defp prepare_predictions(predictions) do
    predictions
    |> Enum.sort_by(fn x -> x.player_id end)
    |> Enum.map(fn x -> {x.player_id, x} end)
    |> Enum.unzip()
  end



  @spec enrich_preds(prepared_raw :: [TTypes.enriched_row()], prepared_processed :: [Medusa.Pipeline.Step2.t()], prepared_predictions :: [Medusa.Port.t()], target_date :: Date.t()) :: [Satellite.MedusaTable.t()]
  defp enrich_preds(prepared_raw, prepared_processed, prepared_predictions, target_date) do
    creation_dt = DateTime.utc_now()
    for {raw, proc, pred} <- Enum.zip([prepared_raw, prepared_processed, prepared_predictions]), do: enrich_map(raw, proc, pred, target_date, creation_dt)
  end

  @spec enrich_map(raw :: TTypes.enriched_row(), proc :: Medusa.Pipeline.Step2.t(), pred :: Medusa.Port.t(), target_date :: Date.t(), creation_dt :: DateTime.t()) :: Satellite.MedusaTable.t()
  defp enrich_map(raw, proc, pred, target_date, creation_dt) do
    %Satellite.MedusaTable{
      player_id: pred.player_id,
      player_name: raw.player_name,
      player_url: pred.player_id,
      alliance_id: raw.alliance_id,
      alliance_name: raw.alliance_name,
      alliance_url: raw.alliance_name,
      inactive_in_future: pred.inactive_in_future,
      inactive_in_current: proc.fe_struct.inactive_in_current,
      total_population: proc.fe_struct.total_population,
      model: pred.model,
      n_villages: proc.fe_struct.n_villages,
      target_date: target_date,
      creation_dt: creation_dt}
  end



end
