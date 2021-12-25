defmodule MedusaPipeline do
  @moduledoc """
  Documentation for `MedusaPipeline`.
  """
  @type input :: {TTypes.player_id(), TTypes.village_id(), TTypes.date(), TTypes.race(), TTypes.population()}
  @type output :: %{player: TTypes.player_id(),
			 date: TTypes.date(),
			 next_day: TTypes.next_day(),
			 n_village: TTypes.n_village(),
			 n_active_village: TTypes.n_active_village(),
			 population: TTypes.population(),
			 population_increase: TTypes.population_increase(),
			 population_decrease: TTypes.population_decrease(),
			 n_races: TTypes.n_races()}


  @spec apply(input :: [input()]) :: [output()]
  def apply(input) do
    input
    |> Enum.group_by(
      fn {player_id, village_id, _, _, _} -> {player_id, village_id} end,
      fn {_, _, date, race, population} -> {date, race, population} end)
    |> Enum.map(&MedusaPipeline.VillageHistoric.create_village_attrs/1)
    |> Enum.filter(fn {{_, _}, village_log} -> village_log != [] end)
    |> Enum.flat_map(&assign_ids/1)
    |> Enum.group_by(
    fn {player_id, _, date, _, _, _, _} -> {player_id, date} end,
    fn {_, _, _, race, population, pop_diff, date_diff} -> {race, population, pop_diff, date_diff} end)
    |> Enum.map(&MedusaPipeline.PlayerHistoric.create_player_attrs/1)
    |> Enum.map(&make_output_map/1)
  end

  @spec assign_ids({{TTypes.player_id(), TTypes.village_id()}, [{TTypes.date(), TTypes.race(), TTypes.population(), TTypes.population_diff(), TTypes.date_diff()}]})
  :: [{TTypes.player_id(), TTypes.village_id(), TTypes.date(), TTypes.race(), TTypes.population(), TTypes.population_diff(), TTypes.date_diff()}]
  defp assign_ids({ids, village_log}), do: Enum.map(village_log, fn vlog -> assing_ids(ids, vlog) end)

  @spec assing_ids({TTypes.player_id(), TTypes.village_id()}, {TTypes.date(), TTypes.race(), TTypes.population(), TTypes.population_diff(), TTypes.date_diff()})
  :: {TTypes.player_id(), TTypes.village_id(), TTypes.date(), TTypes.race(), TTypes.population(), TTypes.population_diff(), TTypes.date_diff()}
  defp assing_ids({player_id, village_id}, {date, race, population, population_diff, date_diff}) do
    {player_id, village_id, date, race, population, population_diff, date_diff}
  end

  @spec make_output_map(step2_tuple :: {TTypes.player_id(), TTypes.date(), TTypes.date_diff(), TTypes.n_village(), TTypes.n_active_village(),
			       TTypes.population(), TTypes.population_increase(), TTypes.population_decrease(), TTypes.n_races()}) :: output()
  defp make_output_map({player_id,
			date,
			date_diff,
			n_village,
			n_active_village,
			population,
			population_increase,
			population_decrease,
			n_races}) do

    %{player: player_id,
      date: date,
      next_day: date_diff,
      n_village: n_village,
      n_active_village: n_active_village,
      population: population,
      population_increase: population_increase,
      population_decrease: population_decrease,
      n_races: n_races}
  end
end
