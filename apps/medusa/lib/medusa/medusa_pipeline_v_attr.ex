defmodule Medusa.PipelineVAttr do

  @moduledoc """
  This is the pipeline step 1, responsible of adding some village attributes to the sample
  """



  @spec create_village_attrs(Medusa.Types.step1_input()) :: Medusa.Types.step1_output()
  def create_village_attrs({{player_id, village_id}, village_log}) do
    output_data = village_log
    |> Enum.sort_by(fn {date, _race, _population} -> date end, {:asc, Date})
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(&get_attributes/1)
    {{player_id, village_id}, output_data}
  end

  @spec get_attributes([Medusa.Types.step1_input_tuple(), ...]) :: Medusa.Types.step1_output_tuple()
  defp get_attributes([{date1, race1, population1}, {date2, _race2, population2}]) do
    population_diff = population2 - population1
    date_diff = Date.diff(date2, date1)
    {date1, race1, population1, population_diff, date_diff}
  end



end
