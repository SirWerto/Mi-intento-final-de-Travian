defmodule Medusa.Pipeline.FE1 do


  @enforce_keys [:player_id, :date, :inactive_in_current, :total_population, :n_villages, :tribes_summary, :center_mass_x, :center_mass_y, :distance_to_origin]
  defstruct [:player_id, :date, :inactive_in_current, :total_population, :n_villages, :tribes_summary, :center_mass_x, :center_mass_y, :distance_to_origin]
  
  @type t :: %__MODULE__{
    player_id: TTypes.player_id(),
    date: Date.t(),
    inactive_in_current: :undefined,
    total_population: pos_integer(),
    n_villages: pos_integer(),
    tribes_summary: TTypes.tribes_map(),
    center_mass_x: float(),
    center_mass_y: float(),
    distance_to_origin: float()}

  @spec apply([Medusa.Pipeline.Step1.t()]) :: t()
  def apply([struct1]) do
    %__MODULE__{
      player_id: struct1.player_id,
      date: struct1.date,
      inactive_in_current: :undefined,
      total_population: struct1.total_population,
      n_villages: struct1.n_villages,
      tribes_summary: struct1.tribes_summary,
      center_mass_x: struct1.center_mass_x,
      center_mass_y: struct1.center_mass_y,
      distance_to_origin: struct1.distance_to_origin}
  end
end
