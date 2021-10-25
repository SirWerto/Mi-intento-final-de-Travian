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
      %{player: "player1", date: ~D[2000-01-01], next_day: 1, n_village: 1, n_active_village: 1, population: 80, population_increase: 1, population_decrease: 0, n_races: 1},
      %{player: "player1", date: ~D[2000-01-02], next_day: 1, n_village: 1, n_active_village: 1, population: 81, population_increase: 1, population_decrease: 0, n_races: 1},

      %{player: "player2", date: ~D[2000-01-01], next_day: 1, n_village: 1, n_active_village: 1, population: 30, population_increase: 1, population_decrease: 0, n_races: 1},
      %{player: "player2", date: ~D[2000-01-02], next_day: 1, n_village: 1, n_active_village: 1, population: 31, population_increase: 1, population_decrease: 0, n_races: 1}
    ]




    assert Medusa.Pipeline.base(input) == output
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

  test "Model 5 days prediction pipeline one player" do
    input = 
      [
	%{
	  date: ~D[2021-10-09],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: 0,
	  population_increase: 0,
	  population: 221
	},
	%{
	  date: ~D[2021-10-10],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: 0,
	  population_increase: 0,
	  population: 221
	},
	%{
	  date: ~D[2021-10-11],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: -4,
	  population_increase: 0,
	  population: 221
	},
	%{
	  date: ~D[2021-10-12],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: -8,
	  population_increase: 0,
	  population: 217
	}
      ]

    output = [%{
      player_id: "https://ts6.x1.america.travian.com--2021-09-23--P188",
      last_day: -0.9837979515735163,
      weekend?: Date.day_of_week(~D[2021-10-12]) == 7,
      pop_increase_day_1: 0,
      pop_increase_day_2: 0,
      pop_increase_day_3: 0,
      pop_increase_day_4: 0,
      max_races: 1,
      end_population: 217,
      total_decrease: -12}]

    assert Medusa.Pipeline.pred_model_5_days(input) == output
  end

  test "Model 5 days prediction pipeline no consecutive days" do
    input = 
      [
	%{
	  date: ~D[2021-10-09],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 2,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: 0,
	  population_increase: 0,
	  population: 221
	},
	%{
	  date: ~D[2021-10-11],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: 0,
	  population_increase: 0,
	  population: 221
	},
	%{
	  date: ~D[2021-10-12],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: -4,
	  population_increase: 0,
	  population: 221
	},
	%{
	  date: ~D[2021-10-13],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: -8,
	  population_increase: 0,
	  population: 217
	}
      ]

    output = []

    assert Medusa.Pipeline.pred_model_5_days(input) == output
  end

  test "tag an active player" do

    input = 
      [
	%{
	  date: ~D[2021-10-08],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: 0,
	  population_increase: 1,
	  population: 220
	},
	%{
	  date: ~D[2021-10-09],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: 0,
	  population_increase: 1,
	  population: 221
	},
	%{
	  date: ~D[2021-10-10],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: 0,
	  population_increase: 1,
	  population: 222
	},
	%{
	  date: ~D[2021-10-11],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: -4,
	  population_increase: 1,
	  population: 223
	},
	%{
	  date: ~D[2021-10-12],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: -8,
	  population_increase: 1,
	  population: 220
	},
	%{
	  date: ~D[2021-10-13],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: 0,
	  population_increase: 1,
	  population: 213
	},
	%{
	  date: ~D[2021-10-14],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: 0,
	  population_increase: 1,
	  population: 214
	},
	%{
	  date: ~D[2021-10-15],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: 0,
	  population_increase: 1,
	  population: 215
	}
      ]

    output = [
      {
	%{
	  player_id: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  last_day: -0.9867305793119814,
	  weekend?: Date.day_of_week(~D[2021-10-11]) == 7,
	  pop_increase_day_1: 1,
	  pop_increase_day_2: 1,
	  pop_increase_day_3: 1,
	  pop_increase_day_4: 1,
	  max_races: 1,
	  end_population: 223,
	  total_decrease: -4},
	:active},
      {
	%{
	  player_id: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  last_day: -0.9837979515735163,
	  weekend?: Date.day_of_week(~D[2021-10-12]) == 7,
	  pop_increase_day_1: 1,
	  pop_increase_day_2: 1,
	  pop_increase_day_3: 1,
	  pop_increase_day_4: 1,
	  max_races: 1,
	  end_population: 220,
	  total_decrease: -12},
	:active}
    ]

    assert Medusa.Pipeline.train_model_5_days(input) == output
  end

  test "future inactive player" do
    input = 
      [
	%{
	  date: ~D[2021-10-08],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: 0,
	  population_increase: 1,
	  population: 220
	},
	%{
	  date: ~D[2021-10-09],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: 0,
	  population_increase: 1,
	  population: 221
	},
	%{
	  date: ~D[2021-10-10],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: 0,
	  population_increase: 1,
	  population: 222
	},
	%{
	  date: ~D[2021-10-11],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: -4,
	  population_increase: 1,
	  population: 223
	},
	%{
	  date: ~D[2021-10-12],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: -8,
	  population_increase: 0,
	  population: 220
	},
	%{
	  date: ~D[2021-10-13],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: 0,
	  population_increase: 0,
	  population: 212
	},
	%{
	  date: ~D[2021-10-14],
	  n_active_village: 0,
	  n_races: 1,
	  n_village: 1,
	  next_day: 1,
	  player: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  population_decrease: 0,
	  population_increase: 0,
	  population: 212
	}]
output = [
      {
	%{
	  player_id: "https://ts6.x1.america.travian.com--2021-09-23--P188",
	  last_day: -0.9867305793119814,
	  weekend?: Date.day_of_week(~D[2021-10-11]) == 7,
	  pop_increase_day_1: 1,
	  pop_increase_day_2: 1,
	  pop_increase_day_3: 1,
	  pop_increase_day_4: 1,
	  max_races: 1,
	  end_population: 223,
	  total_decrease: -4},
	:future_inactive}
    ]

    assert Medusa.Pipeline.train_model_5_days(input) == output
  end
end
