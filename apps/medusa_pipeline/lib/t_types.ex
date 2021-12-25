defmodule TTypes do
  @moduledoc """
  This module contains all the Travian types.
  """

  @typedoc "Player's unique server identifier in Travian. Collected from a map.sql snapshot."
  @type player_id :: String.t()

  @typedoc "Village's unique server identifier in Travian. Collected from a map.sql snapshot."
  @type village_id :: String.t()

  @typedoc "Date of the snapshot."
  @type date :: Date.t()


  @typedoc "It's the race of the village. Can be: 
  1. Romans
  2. Teutons
  3. Gauls
  4. Nature
  5. Natars
  6. Huns
  7. Egyptians"
  @type race :: integer()

  @typedoc "The number of inhabitants wich populates the village."
  @type population :: integer()

  @type population_diff :: integer()
  @type date_diff :: pos_integer()
  @type next_day :: date_diff()
  @type population_increase :: non_neg_integer()
  @type population_decrease :: integer()
  @type n_village :: pos_integer()
  @type n_active_village :: pos_integer()
  @type n_races :: pos_integer()

end
