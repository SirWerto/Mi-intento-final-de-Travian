defmodule Medusa.Pipeline do

  @moduledoc false


  #@type pipe_output :: %{player: player_id(), date: date(), next_date: pos_integer(), n_village: pos_integer(), n_active_village: pos_integer(), population_total: pos_integer(), population_increase: integer(), n_races: pos_integer()}

  @type pipe_output :: any()

  @spec base(Medusa.Types.base_input()) :: [Medusa.Types.base_output()]
  def base(pipe_input) do
    pipe_input
    |> Enum.group_by(
      fn {player_id, village_id, _date, _race, _population} -> {player_id, village_id} end,
      fn {_player_id, _village_id, date, race, population} -> {date, race, population} end)
    |> Enum.map(&Medusa.PipelineVAttr.create_village_attrs/1)
    |> Enum.filter(fn {{_player_id, _village_id}, village_log} -> village_log != [] end)
    |> Enum.flat_map(&flat_player_village/1)
    |> Enum.group_by(
    fn {player_id, _village_id, date, _race, _population, _pop_diff, _date_diff} -> {player_id, date} end,
    fn {_player_id, _village_id, _date, race, population, pop_diff, date_diff} -> {race, population, pop_diff, date_diff} end)

    |> Enum.map(&Medusa.PipelineSummarizeDay.summarize/1)
    |> Enum.map(&make_output_map/1)


  end

  @spec flat_player_village(Medusa.Types.step1_output()) :: [Medusa.Types.flat_step2()]
  defp flat_player_village({{player_id, village_id}, village_log}) do
    village_log
    |> Enum.map(fn {date1, race1, population1, population_diff, date_diff} ->
      {player_id, village_id, date1, race1, population1, population_diff, date_diff} end)
  end

  @spec make_output_map(step2_tuple :: Medusa.Types.step2_output()) :: Medusa.Types.base_output()
  defp make_output_map({player_id,
			date,
			date_diff,
			n_village,
			n_active_village,
			population_total,
			population_increase,
			population_decrease,
			n_races}) do

    %{player: player_id,
      date: date,
      next_day: date_diff,
      n_village: n_village,
      n_active_village: n_active_village,
      population_total: population_total,
      population_increase: population_increase,
      population_decrease: population_decrease,
      n_races: n_races}
  end
end
