defmodule Medusa.Pipeline.FEN do

  # @enforce_keys [:player_id, :date, :total_population, :n_villages, :tribes_summary, :center_mass_x, :center_mass_y, :distance_to_origin]
  # defstruct [:player_id, :date, :total_population, :n_villages, :tribes_summary, :center_mass_x, :center_mass_y, :distance_to_origin]
  
  # @type t :: %__MODULE__{
  #   player_id: TTypes.player_id(),
  #   date: Date.t(),
  #   total_population: pos_integer(),
  #   n_villages: pos_integer(),
  #   tribes_summary: TTypes.tribes_map(),
  #   center_mass_x: float(),
  #   center_mass_y: float(),
  #   distance_to_origin: float()}


  @enforce_keys [:center_mass_x, :center_mass_y, :date, :n_days, :dow, :distance_to_origin,
		 :n_village_decrease, :n_village_increase, :n_villages, :player_id,
		 :inactive_in_current, :prev_distance_to_origin, :total_population, :total_population_decrease,
		 :total_population_increase, :tribes_summary]
  defstruct [:center_mass_x, :center_mass_y, :date, :n_days, :dow, :distance_to_origin,
	     :n_village_decrease, :n_village_increase, :n_villages, :player_id,
	     :inactive_in_current, :prev_distance_to_origin, :total_population, :total_population_decrease,
	     :total_population_increase, :tribes_summary]
  
  
  @type t :: %__MODULE__{
    player_id: TTypes.player_id(),
    date: Date.t(),
    inactive_in_current: boolean(),
    n_days: pos_integer(),
    dow: pos_integer(),
    total_population: pos_integer(),
    total_population_increase: non_neg_integer(),
    total_population_decrease: non_neg_integer(),
    n_villages: pos_integer(),
    n_village_increase: non_neg_integer(),
    n_village_decrease: non_neg_integer(),
    tribes_summary: TTypes.tribes_map(),
    center_mass_x: float(),
    center_mass_y: float(),
    distance_to_origin: float(),
    prev_distance_to_origin: float()}





  @spec apply([Medusa.Pipeline.Step1.t()]) :: t()
  def apply(structs) do
    [struct_first | [struct_second | _]] = structs
    struct_last = List.last(structs)

    pops = for x <- structs, do: x.total_population
    vills = for x <- structs, do: x.n_villages
    
    {inc, dec} = Medusa.Utils.compute_inc_dec(pops)
    {inc_v, dec_v} = Medusa.Utils.compute_inc_dec(vills)
    n_days = length(structs)

    %__MODULE__{
      player_id: struct_first.player_id,
      date: struct_first.date,
      inactive_in_current: !Medusa.Pipeline.active_day?(struct_second.village_pop, struct_first.village_pop),
      n_days: n_days,
      dow: Date.day_of_week(struct_first.date),
      total_population: struct_first.total_population,
      total_population_increase: inc,
      total_population_decrease: dec,
      n_villages: struct_first.n_villages,
      n_village_increase: inc_v,
      n_village_decrease: dec_v,
      tribes_summary: struct_first.tribes_summary,
      center_mass_x: struct_first.center_mass_x,
      center_mass_y: struct_first.center_mass_y,
      distance_to_origin: struct_first.distance_to_origin,
      prev_distance_to_origin: struct_last.distance_to_origin}

    # %__MODULE__{
    #   player_id: struct1.player_id,
    #   date: struct1.date,
    #   total_population: struct1.total_population,
    #   n_villages: struct1.n_villages,
    #   tribes_summary: struct1.tribes_summary,
    #   center_mass_x: struct1.center_mass_x,
    #   center_mass_y: struct1.center_mass_y,
    #   distance_to_origin: struct1.distance_to_origin}
  end
end
