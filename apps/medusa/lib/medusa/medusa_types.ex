defmodule Medusa.Types do
  @moduledoc """
  This module has all the types used by Medusa
  """


  @type player_id :: String.t()
  @type village_id :: String.t()
  @type date :: Date.t()
  @type date_diff :: pos_integer() # number of days untile the next record
  @type race :: integer()
  @type population :: integer()
  @type population_diff :: integer()


  @type next_day :: date_diff()
  @type population_increase :: non_neg_integer()
  @type population_decrease :: integer()
  @type n_village :: pos_integer()
  @type n_active_village :: pos_integer()
  @type n_races :: pos_integer()

  ## Base Pipeline Types
  @type base_input :: {player_id(), village_id(), date(), race(), population()}
  @type base_output :: %{player: player_id(),
			 date: date(),
			 next_day: next_day(),
			 n_village: n_village(),
			 n_active_village: n_active_village(),
			 population: population(),
			 population_increase: population_increase(),
			 population_decrease: population_decrease(),
			 n_races: n_races()}
  ## ## Create Village Attr - Step1
  ## ## ## Input
  @type step1_input_tuple :: {date(), race(), population()}
  @type step1_input_data :: [step1_input_tuple()]
  @type step1_input :: {{player_id(), village_id()}, step1_input_data()}
  ## ## ## Output
  @type step1_output_tuple :: {date(), race(), population(), population_diff(), date_diff()}
  @type step1_output_data :: [step1_output_tuple()]
  @type step1_output :: {{player_id(), village_id()}, step1_output_data()}
  ## ## Summarize Day - Step2
  ## ## ## Input
  @type flat_step2 :: {player_id(), village_id(), date(), race(), population(), population_diff(), date_diff()}
  @type step2_input_tuple :: {race(), population(), population_diff(), date_diff()}
  @type step2_input_data :: [step2_input_tuple()]
  @type step2_input :: {{player_id(), date()}, step2_input_data()}
  ## ## ## Output
  @type step2_output:: {player_id(), date(), date_diff(), n_village(), n_active_village(),
			       population(), population_increase(), population_decrease(), n_races()}



  ## Feature Engineer
  ## ## 5 days model
  @type fe_5_input :: {base_output(), base_output(), base_output(), base_output(), base_output()}
  @type fe_5_output :: %{player_id: player_id(),
			last_day: float(),
			weekend?: boolean(),
			pop_increase_day_1: population_increase(),
			pop_increase_day_2: population_increase(),
			pop_increase_day_3: population_increase(),
			pop_increase_day_4: population_increase(),
			pop_increase_day_5: population_increase(),
			max_races: pos_integer(),
			end_population: population(),
			total_decrease: integer()}
end
