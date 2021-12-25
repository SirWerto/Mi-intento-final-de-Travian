defmodule MedusaPipeline.VillageHistoric do

  @moduledoc """
  This module transform village's raw data to multiple tuples with growth information.
  """

  @type date_diff :: pos_integer() # number of days untile the next record
  @type population_diff :: integer()

  @type input_tuple :: {TTypes.date(), TTypes.race(), TTypes.population()}
  @type input_data :: [input_tuple()]
  @type input :: {{TTypes.player_id(), TTypes.village_id()}, input_data()}

  @type output_tuple :: {TTypes.date(), TTypes.race(), TTypes.population(), population_diff(), date_diff()}
  @type output_data :: [output_tuple()]
  @type output :: {{TTypes.player_id(), TTypes.village_id()}, output_data()}

  @doc ~S"""
  It recives an activity track of one village and returns a list of tuple with custom activity related information.
  
  The result is a list of tuples with some special attributes:

  `[{date, race, population, population_diff, date_diff}]`

  - `date` -> Date of the snapshot.
  - `race` -> Race of the village.
  - `population` -> Day's initial population.
  - `population_diff` -> Population growth until next snapshot date. Could be positive, negative or 0.
  - `date_diff` -> Difference in days bettween snapshots.
  
  ## Example
      iex> player_id = "player1"  #the owner of the village in this date
      iex> village_id = "village1"  #the village identifier
      iex> 
      iex> # {date, race, population}
      iex> # This tuple is an snapshot of the village attributes in the day date at the morning
      iex> 
      iex> day1 = {~D[2021-10-22], 1, 80}  
      iex> day2 = {~D[2021-10-23], 1, 90}
      iex> day3 = {~D[2021-10-24], 1, 100}
      iex> day4 = {~D[2021-10-25], 1, 95}
      iex> day5 = {~D[2021-10-27], 1, 95}
      iex> village_log = [day1, day2, day3, day4, day5]
      iex> 
      iex> Medusa.VillageHistoric.create_village_attrs({{player_id, village_id}, village_log})
      iex> {player_id, village_id, [{~D[2021-10-22], 1, 80, 10, 1},
      iex>                          {~D[2021-10-23], 1, 90, 10, 1},
      iex>                          {~D[2021-10-24], 1, 100, -5, 1},
      iex>                          {~D[2021-10-25], 1, 95, 0, 0}
      iex>                         ]}
      iex> 

  """
  @spec create_village_attrs(input()) :: output()
  def create_village_attrs({{player_id, village_id}, village_log}) do
    output_data = village_log
    |> Enum.sort_by(fn {date, _race, _population} -> date end, {:asc, Date})
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(&get_attributes/1)
    {{player_id, village_id}, output_data}
  end

  @spec get_attributes([input_tuple(), ...]) :: output_tuple()
  defp get_attributes([{date1, race1, population1}, {date2, _race2, population2}]) do
    population_diff = population2 - population1
    date_diff = Date.diff(date2, date1)
    {date1, race1, population1, population_diff, date_diff}
  end



end
