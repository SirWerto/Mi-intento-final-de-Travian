defmodule PipelineTest do
  use ExUnit.Case
  doctest Medusa


  test "Pipeline with 3 days for :non_enought_days results" do
    input = [
      {"player2", "village1", ~D[2000-01-01], 1, 30},
      {"player2", "village1", ~D[2000-01-03], 1, 32},
      {"player2", "village1", ~D[2000-01-02], 1, 31},
      
      {"player1", "village1", ~D[2000-01-01], 1, 80},
      {"player1", "village1", ~D[2000-01-02], 1, 81},
      {"player1", "village2", ~D[2000-01-02], 1, 91},
      {"player1", "village1", ~D[2000-01-03], 1, 82}
    ]

    output = [
      %{player: "player1", date: ~D[2000-01-01], next_day: 1, n_village: 1, n_active_village: 1, population_total: 80, population_increase: 1, population_decrease: 0, n_races: 1},
      %{player: "player1", date: ~D[2000-01-02], next_day: 1, n_village: 1, n_active_village: 1, population_total: 81, population_increase: 1, population_decrease: 0, n_races: 1},

      %{player: "player2", date: ~D[2000-01-01], next_day: 1, n_village: 1, n_active_village: 1, population_total: 30, population_increase: 1, population_decrease: 0, n_races: 1},
      %{player: "player2", date: ~D[2000-01-02], next_day: 1, n_village: 1, n_active_village: 1, population_total: 31, population_increase: 1, population_decrease: 0, n_races: 1}
    ]




    assert Medusa.Pipeline.base(input) == output
  end

  test "Test creation of new village attributes" do
    input = {{"player1", "village1"}, [{~D[2000-01-01], 1, 80},
				       {~D[2000-01-09], 1, 81},
				       {~D[2000-01-03], 1, 80},
				       {~D[2000-01-05], 1, 84},
				       {~D[2000-01-08], 1, 86},
				       {~D[2000-01-02], 1, 80}]}

    output = {{"player1", "village1"}, [{~D[2000-01-01], 1, 80, 0, 1},
					{~D[2000-01-02], 1, 80, 0, 1},
					{~D[2000-01-03], 1, 80, 4, 2},
					{~D[2000-01-05], 1, 84, 2, 3},
					{~D[2000-01-08], 1, 86, -5, 1}]}

    assert Medusa.PipelineVAttr.create_village_attrs(input) == output
  end



  test "Summarizing the player day information" do
    input = {{"player1", ~D[2000-01-01]}, [{1, 80, 1, 1},
					   {2, 100, 0, 1},
					   {1, 20, 5, 1},
					   {1, 81, 1, 1}]}

  output = 
    {"player1", ~D[2000-01-01], 1, 4, 3, 281, 7, 0, 2}

  assert Medusa.PipelineSummarizeDay.summarize(input) == output
  end

end
