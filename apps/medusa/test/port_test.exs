defmodule Medusa.Port.Test do
  use ExUnit.Case


  setup_all do
    fen = %Medusa.Pipeline.FEN{
    player_id: "player_id",
    date: ~D[2022-01-02],
    inactive_in_current: false,
    n_days: 3,
    dow: 7,
    total_population: 100,
    total_population_increase: 50,
    total_population_decrease: 10,
    n_villages: 3,
    n_village_increase: 0,
    n_village_decrease: 0,
    tribes_summary: %{romans: 3},
    center_mass_x: 1,
    center_mass_y: 1,
    distance_to_origin: 2,
    prev_distance_to_origin: 2
    }


    fe1 = %Medusa.Pipeline.FE1{

    player_id: "player_id",
    date: ~D[2022-01-02],
    inactive_in_current: :undefined,
    total_population: 100,
    n_villages: 3,
    tribes_summary: %{romans: 3},
    center_mass_x: 1,
    center_mass_y: 1,
    distance_to_origin: 2,
    }

    sample_n = %Medusa.Pipeline.Step2{fe_type: :ndays_n, fe_struct: fen}
    sample_1 = %Medusa.Pipeline.Step2{fe_type: :ndays_1, fe_struct: fe1}

    %{sample_n: sample_n, sample_1: sample_1}
  end

  setup do
    {port, ref} = Medusa.Port.open(System.fetch_env!("MITRAVIAN__MEDUSA_MODEL_DIR"))
    on_exit(fn -> Medusa.Port.close(port, ref) end)
    %{port: port, ref: ref}
  end

  test "Input is step2 and output is just Medusa.Port.t() -> %{player_id: player_id, inactive_in_future: true | false}", %{port: port, sample_n: sample_n, sample_1: sample_1} do

    [predict_n, predict_1] = Medusa.Port.predict!(port, [sample_n, sample_1])

    assert(is_boolean(predict_1.inactive_in_future))
    assert(is_boolean(predict_n.inactive_in_future))
  end
end
