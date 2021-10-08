defmodule Medusa.PipelineSummarizeDay do

  @moduledoc """
  This is the pipeline step 2, it is responsible of summarizing the information of one player's day
  """


  @spec summarize(Medusa.Types.step2_input()) :: Medusa.Types.step2_output()
  def summarize({{player_id, date}, villages}) do
    {_race, _pop, _pop_diff, date_diff} = hd(villages)

    active_pops = for {_race, _pop, pop_diff, _date_diff} <- villages, pop_diff > 0, do: pop_diff

    n_races = for {race, _pop, _pop_diff, _date_diff} <- villages, do: race
    n_races = Enum.uniq(n_races) |> length()

    population_total = for {_race, pop, _pop_diff, _date_diff} <- villages, do: pop
    population_total = Enum.sum(population_total)
    population_increase = Enum.sum(active_pops)
    population_decrease = for {_race, pop, _pop_diff, _date_diff} <- villages, pop < 0, do: pop
    population_decrease = Enum.sum(population_decrease)
    n_village = length(villages)
    n_active_village = length(active_pops)
    {player_id, date, date_diff, n_village, n_active_village, population_total, population_increase, population_decrease, n_races}
  end
end
