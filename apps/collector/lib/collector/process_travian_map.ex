defmodule Collector.ProcessTravianMap do


  @spec enriched_map(travian_tuple :: TTypes.snapshot_row(), server_id :: TTypes.server_id()) :: TTypes.enriched_row()
  def enriched_map(travian_tuple, server_id)
  def enriched_map({grid_position,
		    x_position,
		    y_position,
		    tribe,
		    village_server_id,
		    village_name,
		    player_server_id,
		    player_name,
		    alliance_server_id,
		    alliance_name,
		    population,
		    region,
		    undef_1,
		    undef_2,
		    victory_points}, server_id) do
    %{
      grid_position: grid_position,
      x: x_position,
      y: y_position,
      tribe: tribe,
      village_id: make_village_id(server_id, village_server_id),
      village_name: village_name,
      player_id: make_player_id(server_id, player_server_id),
      player_name: player_name,
      alliance_id: make_alliance_id(server_id, alliance_server_id),
      alliance_name: alliance_name,
      population: population,
      region: region,
      undef_1: undef_1,
      undef_2: undef_2,
      victory_points: victory_points
    }
  end

  @spec compare_server_info(old_info :: TTypes.server_info(), new_info :: TTypes.server_info()) :: :not_necessary | TTypes.server_info()
  def compare_server_info(old_info, new_info)
  def compare_server_info(equal_info, equal_info), do: :not_necessary
  def compare_server_info(old_info, new_info), do: Map.merge(old_info, new_info)


  @spec make_village_id(server_id :: TTypes.server_id(), v_server_id :: TTypes.village_server_id()) :: TTypes.village_id()
  defp make_village_id(server_id, v_server_id), do: server_id <> "--V--" <> Integer.to_string(v_server_id)
  @spec make_player_id(server_id :: TTypes.server_id(), p_server_id :: TTypes.player_server_id()) :: TTypes.player_id()
  defp make_player_id(server_id, p_server_id), do: server_id <> "--P--" <> Integer.to_string(p_server_id)
  @spec make_alliance_id(server_id :: TTypes.server_id(), a_server_id :: TTypes.alliance_server_id()) :: TTypes.alliance_id()
  defp make_alliance_id(server_id, a_server_id), do: server_id <> "--A--" <> Integer.to_string(a_server_id)

end
