defmodule MedusaPipeline.PlayerHistoric do

  @moduledoc """
  This module summarize players's information of one day.
  """
  @type input_tuple :: {TTypes.race(), TTypes.population(), TTypes.population_diff(), TTypes.date_diff()}
  @type input_data :: [input_tuple()]
  @type input :: {{TTypes.player_id(), TTypes.date()}, input_data()}

  @type output:: {TTypes.player_id(),
		  TTypes.date(),
		  TTypes.date_diff(),
		  TTypes.n_village(), 
		  TTypes.n_active_village(),
		  TTypes.population(),
		  TTypes.population_increase(),
		  TTypes.population_decrease(),
		  TTypes.n_races()}

  @doc ~S"""

  The result is a tuple with some special attributes:

  `{player_id, date, date_diff, n_village, n_active_village, population_total, population_increase, population_decrease, n_races}`

  - `player_id` -> Player identifier.
  - `date` -> Date of the snapshot.
  - `date_diff` -> Difference in days bettween snapshots.
  - `n_village` -> Number of villages which `player_id` owns in the current `date`.
  - `n_active_village` -> Number of villages with positive `population_diff` this `date`.
  - `population_total` -> Day's initial population.
  - `population_increase` -> Population growth.
  - `population_decrease` -> Population negative growth.
  - `n_races` -> Number of different races in their villages.

  `population_increase` and `population_decrease` can be both different from 0 because can be some villages
  which loose population and other which gain population. As a recordatory, `population_increase` and 
  `population_decrease` are the population modifiers of the current `date`.
  
  ## Example
      iex> player_id = "player1"  #the owner of the village in this date
      iex> date = ~D[2021-10-22]  #the date of the snapshot
      iex> # {player_id, date, date_diff, n_village, n_active_village, population_total, population_increase, population_decrease, n_races} 
      iex> # {race, population, population_diff, date_diff}
      iex> 
      iex> village1 = {1, 80, 5, 1}  
      iex> village2 = {2, 90, 14, 1}
      iex> village3 = {1, 100, 22, 1}
      iex> village4 = {2, 95, -2, 1}
      iex> village5 = {3, 95, 0, 1}
      iex> villages = [village1, village2, village3, village4, village5]
      iex> 
      iex> MedusaPipeline.PlayerHistoric.create_player_attrs({{player_id, date}, villages})
      iex> {player_id, date, 1, 5, 3, 460, 41, 0, 3}

  """
  @spec create_player_attrs(input()) :: output()
  def create_player_attrs({{player_id, date}, villages}) do
    {_race, _pop, _pop_diff, date_diff} = hd(villages)

    active_pops = for {_race, _pop, pop_diff, _date_diff} <- villages, pop_diff > 0, do: pop_diff

    n_races = for {race, _pop, _pop_diff, _date_diff} <- villages, do: race
    n_races = Enum.uniq(n_races) |> length()

    population_total = for {_race, pop, _pop_diff, _date_diff} <- villages, do: pop
    population_total = Enum.sum(population_total)
    population_increase = Enum.sum(active_pops)
    population_decrease = for {_race, _pop, pop_diff, _date_diff} <- villages, pop_diff < 0, do: pop_diff
    population_decrease = Enum.sum(population_decrease)
    n_village = length(villages)
    n_active_village = length(active_pops)
    {player_id, date, date_diff, n_village, n_active_village, population_total, population_increase, population_decrease, n_races}
  end
end
