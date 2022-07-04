defmodule MedusaModelsTest do
  use ExUnit.Case
  doctest MedusaModels

  test "model 5d apply" do
    input = [
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

    output = [
      %{
        player_id: "https://ts6.x1.america.travian.com--2021-09-23--P188",
        last_day: -0.9837979515735163,
        weekend?: Date.day_of_week(~D[2021-10-12]) == 7,
        pop_increase_day_1: 0,
        pop_increase_day_2: 0,
        pop_increase_day_3: 0,
        pop_increase_day_4: 0,
        max_races: 1,
        end_population: 217,
        total_decrease: -12
      }
    ]

    assert MedusaModels.Model5D.apply(input) == output
  end

  test "model 5d apply_train" do
    input = [
      %{
        date: ~D[2021-10-06],
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
        date: ~D[2021-10-07],
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
        date: ~D[2021-10-08],
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

    output = [
      %{
        player_id: "https://ts6.x1.america.travian.com--2021-09-23--P188",
        last_day: -0.9837979515735163,
        weekend?: Date.day_of_week(~D[2021-10-12]) == 7,
        pop_increase_day_1: 0,
        pop_increase_day_2: 0,
        pop_increase_day_3: 0,
        pop_increase_day_4: 0,
        max_races: 1,
        end_population: 217,
        total_decrease: -12
      }
    ]

    assert MedusaModels.Model5D.apply_train(input) == output
  end
end
