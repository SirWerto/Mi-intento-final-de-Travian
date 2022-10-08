defmodule Collector.SnapshotRow do
  @enforce_keys [
    :grid_position,
    :x,
    :y,
    :tribe,
    :village_id,
    :village_server_id,
    :village_name,
    :player_id,
    :player_server_id,
    :player_name,
    :alliance_id,
    :alliance_server_id,
    :alliance_name,
    :population,
    :region,
    :is_capital,
    :is_city,
    :victory_points
  ]

  defstruct [
    :grid_position,
    :x,
    :y,
    :tribe,
    :village_id,
    :village_server_id,
    :village_name,
    :player_id,
    :player_server_id,
    :player_name,
    :alliance_id,
    :alliance_server_id,
    :alliance_name,
    :population,
    :region,
    :is_capital,
    :is_city,
    :victory_points
  ]

  @type t :: %__MODULE__{
          grid_position: TTypes.grid_position(),
          x: TTypes.x(),
          y: TTypes.y(),
          tribe: TTypes.tribe(),
          village_id: TTypes.village_id(),
          village_server_id: TTypes.village_server_id(),
          village_name: TTypes.village_name(),
          player_id: TTypes.player_id(),
          player_server_id: TTypes.player_server_id(),
          player_name: TTypes.player_name(),
          alliance_id: TTypes.alliance_id(),
          alliance_server_id: TTypes.alliance_server_id(),
          alliance_name: TTypes.alliance_name(),
          population: TTypes.population(),
          region: TTypes.region(),
          is_capital: TTypes.is_capital(),
          is_city: TTypes.is_city(),
          victory_points: TTypes.victory_points()
        }

  @spec apply(server_id :: TTypes.server_id(), TTypes.snapshot_row()) :: t()
  def apply(
        server_id,
        {grid_position, x_position, y_position, tribe, village_server_id, village_name,
         player_server_id, player_name, alliance_server_id, alliance_name, population, region,
         is_capital, is_city, victory_points}
      ) do
    %__MODULE__{
      grid_position: grid_position,
      x: x_position,
      y: y_position,
      tribe: tribe,
      village_id: make_village_id(server_id, village_server_id),
      village_server_id: village_server_id,
      village_name: village_name,
      player_id: make_player_id(server_id, player_server_id),
      player_server_id: player_server_id,
      player_name: player_name,
      alliance_id: make_alliance_id(server_id, alliance_server_id),
      alliance_server_id: alliance_server_id,
      alliance_name: alliance_name,
      population: population,
      region: region,
      is_capital: is_capital,
      is_city: is_city,
      victory_points: victory_points
    }
  end

  @spec make_village_id(
          server_id :: TTypes.server_id(),
          v_server_id :: TTypes.village_server_id()
        ) :: TTypes.village_id()
  defp make_village_id(server_id, v_server_id),
    do: server_id <> "--V--" <> Integer.to_string(v_server_id)

  @spec make_player_id(server_id :: TTypes.server_id(), p_server_id :: TTypes.player_server_id()) ::
          TTypes.player_id()
  defp make_player_id(server_id, p_server_id),
    do: server_id <> "--P--" <> Integer.to_string(p_server_id)

  @spec make_alliance_id(
          server_id :: TTypes.server_id(),
          a_server_id :: TTypes.alliance_server_id()
        ) :: TTypes.alliance_id()
  defp make_alliance_id(server_id, a_server_id),
    do: server_id <> "--A--" <> Integer.to_string(a_server_id)
end
