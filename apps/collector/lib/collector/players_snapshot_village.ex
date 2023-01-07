defmodule Collector.PlayersSnapshot.Village do

  @enforce_keys [
    :village_id,
    :x,
    :y,
    :population,
    :tribe,
    :region,
    :is_capital,
    :is_city,
    :victory_points
  ]

  defstruct [
    :village_id,
    :x,
    :y,
    :population,
    :tribe,
    :region,
    :is_capital,
    :is_city,
    :victory_points
  ]

  @type t :: %__MODULE__{
    village_id: TTypes.player_id(),
    x: integer(),
    y: integer(),
    population: non_neg_integer(),
    tribe: TTypes.tribe_integer(),
    region: TTypes.region(),
    is_capital: TTypes.is_capital(),
    is_city: TTypes.is_city(),
    victory_points: TTypes.victory_points()
  }

end
