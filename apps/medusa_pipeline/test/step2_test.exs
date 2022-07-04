defmodule MedusaPipelineStep2Test do
  use ExUnit.Case

  test "Analice one player" do
    input = [
      [
        %Step1{
          player_id: "player_id",
          date: ~D[2022-01-02],
          total_population: 39,
          n_villages: 1,
          tribes_summary: %{romans: 1},
          center_mass_x: 1.0,
          center_mass_y: 2.0,
          distance_to_origin: 2.24
        }
      ],
      [
        %Step1{
          player_id: "player_id",
          date: ~D[2022-01-01],
          total_population: 80,
          n_villages: 2,
          tribes_summary: %{romans: 1, gauls: 1},
          center_mass_x: 3.0,
          center_mass_y: 3.0,
          distance_to_origin: 4.24
        }
      ]
    ]

    output = [
      %Step2{
        player_id: "player_id",
        date: ~D[2022-01-02],
        total_population: 39,
        total_population_increase: 0,
        total_population_decrease: 41,
        n_villages: 1,
        n_village_increase: 0,
        n_village_decrease: 1,
        tribes_summary: %{romans: 1},
        center_mass_x: 1.0,
        center_mass_y: 2.0,
        distance_to_origin: 2.24,
        prev_distance_to_origin: 4.24
      }
    ]

    assert output == Step2.process_2_snapshots(input)
  end
end
