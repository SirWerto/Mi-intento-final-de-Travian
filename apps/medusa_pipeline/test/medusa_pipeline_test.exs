defmodule MedusaPipelineTest do
  use ExUnit.Case
  doctest MedusaPipeline

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
      %{player: "player1", date: ~D[2000-01-01], next_day: 1, n_village: 1, n_active_village: 1, population: 80, population_increase: 1, population_decrease: 0, n_races: 1},
      %{player: "player1", date: ~D[2000-01-02], next_day: 1, n_village: 1, n_active_village: 1, population: 81, population_increase: 1, population_decrease: 0, n_races: 1},

      %{player: "player2", date: ~D[2000-01-01], next_day: 1, n_village: 1, n_active_village: 1, population: 30, population_increase: 1, population_decrease: 0, n_races: 1},
      %{player: "player2", date: ~D[2000-01-02], next_day: 1, n_village: 1, n_active_village: 1, population: 31, population_increase: 1, population_decrease: 0, n_races: 1}
    ]




    assert MedusaPipeline.apply(input) == output
  end


  test "Decrease population base pipeline" do
    input = [
      {"https://ts6.x1.america.travian.com--2021-09-23--P188",
       "https://ts6.x1.america.travian.com--2021-09-23--V385", ~D[2021-10-11], 3,
       221},
      {"https://ts6.x1.america.travian.com--2021-09-23--P188",
       "https://ts6.x1.america.travian.com--2021-09-23--V385", ~D[2021-10-12], 3,
       217},
      {"https://ts6.x1.america.travian.com--2021-09-23--P188",
       "https://ts6.x1.america.travian.com--2021-09-23--V385", ~D[2021-10-13], 3,
       209}]

    output = 
      [
	%{
	  date: ~D[2021-10-11],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population: 221,
	  population_decrease: -4,
	  population_increase: 0
	},
	%{
	  date: ~D[2021-10-12],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population: 217,
	  population_decrease: -8,
	  population_increase: 0
	}]
    assert MedusaPipeline.apply(input) == output
  end

end
