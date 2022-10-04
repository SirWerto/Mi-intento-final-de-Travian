defmodule MedusaTrain.ET do
  require Logger

  @spec apply(root_folder :: binary(), server_id :: TTypes.server_id(), target_date :: Date.t()) ::
          {:ok, [{bool(), Medusa.Pipeline.Step1.t()}]} | {:error, any()}
  def apply(root_folder, server_id, target_date) do
    day_before = Date.add(target_date, -1)

    date_options = {Date.add(day_before, 1 - 5), day_before, :consecutive}

    with(
      Logger.debug(%{
        msg: "MedusaTrain ET step 1, open metrics",
        server_id: server_id,
        target_date: target_date
      }),
      {:step_1, {:ok, {_date, encoded_predictions}}} <-
        {:step_1, Storage.open(root_folder, server_id, Medusa.predictions_options(), target_date)},
      predictions = Medusa.predictions_from_format(encoded_predictions),
      {players_ids_to_process, sorted_status} = players_to_process(predictions),
      Logger.debug(%{
        msg: "MedusaTrain ET step 2, open historic snapshots",
        server_id: server_id,
        target_date: target_date
      }),
      {:step_2, {:ok, encoded_snapshots}} <-
        {:step_2,
         Storage.open(root_folder, server_id, Collector.snapshot_options(), date_options)},
      snapshots =
        Enum.map(encoded_snapshots, fn {d, v} -> {d, Collector.snapshot_from_format(v)} end),
      Logger.debug(%{
        msg: "MedusaTrain ET step 3, historic exists?",
        server_id: server_id,
        target_date: target_date
      }),
      {:step_3, false} <- {:step_3, snapshots == []},
      Logger.debug(%{
        msg: "MedusaTrain ET step 4, process the snapshots",
        server_id: server_id,
        target_date: target_date
      }),
      {:step_4, processed} = {:step_4, Medusa.Pipeline.apply(snapshots)}
    ) do
      Logger.debug(%{
        msg: "MedusaTrain ET step 5, tag the samples",
        server_id: server_id,
        target_date: target_date
      })

      tagged_processed =
        processed
        |> Enum.filter(fn x -> x.fe_struct.player_id in players_ids_to_process end)
        |> Enum.sort_by(fn x -> x.fe_struct.player_id end)
        |> Enum.zip(sorted_status)
        |> Enum.map(fn {x, status} -> %{"inactive_in_future" => status, "sample" => x} end)

      {:ok, tagged_processed}
    else
      {:step_1, {:error, reason}} ->
        Logger.warning(%{
          msg: " MedusaTrain ET error",
          step: 1,
          reason: reason,
          server_id: server_id,
          target_date: target_date
        })

        {:error, reason}

      {:step_2, reason} ->
        Logger.warning(%{
          msg: " MedusaTrain ET error",
          step: 2,
          reason: reason,
          server_id: server_id,
          target_date: target_date
        })

        {:error, reason}

      {:step_3, reason} ->
        Logger.warning(%{
          msg: " MedusaTrain ET error",
          step: 3,
          reason: reason,
          server_id: server_id,
          target_date: target_date
        })

        {:error, reason}

      {:step_4, reason} ->
        Logger.warning(%{
          msg: " MedusaTrain ET error",
          step: 4,
          reason: reason,
          server_id: server_id,
          target_date: target_date
        })

        {:error, reason}
    end
  end

  defp players_to_process(predictions) do
    predictions
    |> Enum.filter(fn pred -> pred.inactive_in_current != :undefined end)
    |> Enum.sort_by(fn pred -> pred.player_id end)
    |> Enum.map(fn pred -> {pred.player_id, pred.inactive_in_current} end)
    |> Enum.unzip()
  end
end
