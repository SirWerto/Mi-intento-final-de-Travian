defmodule Collector.PlayersSnapshot do

  @enforce_keys [
    :player_id,
    :alliance_id,
    :n_villages,
    :total_population,
    :villages
  ]

  defstruct [
    :player_id,
    :alliance_id,
    :n_villages,
    :total_population,
    :villages
  ]

  @type t :: %__MODULE__{
    player_id: TTypes.player_id(),
    alliance_id: TTypes.alliance_id(),
    n_villages: pos_integer(),
    total_population: non_neg_integer(),
    villages: [Collector.PlayersSnapshot.Village.t(), ...]
    }

  @spec group(snapshot_rows :: [Collector.SnapshotRow.t()]) :: t()
  def group(snapshot_rows) do
    snapshot_rows
    |> Enum.group_by(&(&1.player_id))
    |> Enum.map(&apply_format/1)
  end

  defp apply_format({player_id, rows}) do
    %__MODULE__{
      player_id: player_id,
      alliance_id: hd(rows).alliance_id,
      n_villages: length(rows),
      total_population: Enum.reduce(rows, 0, &(&1.population + &2)),
      villages: Enum.map(rows, &extract_village/1)
    }
  end

  defp extract_village(row) do
    %Collector.PlayersSnapshot.Village{
      village_id: row.village_id,
      x: row.x,
      y: row.y,
      population: row.population,
      tribe: row.tribe,
      region: row.region,
      is_capital: row.is_capital,
      is_city: row.is_city,
      victory_points: row.victory_points
    }
  end
end
