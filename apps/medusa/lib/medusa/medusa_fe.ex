defmodule Medusa.FE do

  @moduledoc """
  Medusa future engineer module for multiple models
  """

  @year_cycle 2*:math.pi/366

  @doc """
  This function does the future engineer step betwen the sample(described below) and 
  the current model for 5 days.
  
  The sample must be 5 consecutive in days and same player_id maps from the base pipeline.
  """
  @spec model_5_days(Medusa.Types.fe_5_input()) :: Medusa.Types.fe_5_output()
  def model_5_days(sample = {_, _, _, last}) do
    %{
      player_id: last[:player],
      last_day: transform_day(last[:date]),
      weekend?: is_weekend?(last[:date]),
      pop_increase_day_1: Map.fetch!(elem(sample, 0), :population_increase),
      pop_increase_day_2: Map.fetch!(elem(sample, 1), :population_increase),
      pop_increase_day_3: Map.fetch!(elem(sample, 2), :population_increase),
      pop_increase_day_4: Map.fetch!(elem(sample, 3), :population_increase),
      max_races: max_races(sample),
      end_population: last[:population],
      total_decrease: total_decrease(sample)}
  end


  @spec is_weekend?(day :: Date.t()) :: boolean()
  defp is_weekend?(day) do
    Date.day_of_week(day) == 7
  end

  @spec transform_day(day :: Date.t()) :: float()
  defp transform_day(day) do
    y_day = Date.day_of_year(day)
    :math.sin(y_day * @year_cycle)
  end

  @spec max_races(Medusa.Types.fe_5_input()) :: Medusa.Types.n_races()
  defp max_races(sample) do
    Enum.max(Tuple.to_list(sample), fn x, y -> x[:n_races] >= y[:n_races] end) |> Map.fetch!(:n_races)
  end

  @spec total_decrease(Medusa.Types.fe_5_input()) :: Medusa.Types.population_decrease()
  defp total_decrease(sample) do
    Tuple.to_list(sample)
    |> Enum.map(fn x -> x[:population_decrease] end)
    |> Enum.sum()
  end

end
