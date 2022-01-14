defmodule Medusa.CombineAttrs do

  @spec combine([{binary(), binary()}], [{binary(), binary(), binary(), pos_integer(), pos_integer()}]) 
  :: [{binary(), binary(), binary(), binary(), pos_integer(), pos_integer()}]
  def combine(players, extra_attrs) do

    players_map = Map.new(players, fn {player_id, state} -> {player_id, {player_id, state}} end)
    extra_attrs_map = Map.new(extra_attrs, fn tuple = {player_id, _, _, _, _} -> {player_id, tuple} end)

    Map.merge(players_map, extra_attrs_map, &merge_map/3) |> Map.values()
  end

  defp merge_map(player_id, {player_id, state}, {player_id, name, a_name, n_villages, total_pop}) do
    {player_id, state, name, a_name, n_villages, total_pop}
  end
end
