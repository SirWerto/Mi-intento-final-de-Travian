defmodule Medusa.Port.Test do
  use ExUnit.Case


  setup_all do
    fen = %Medusa.Pipeline.FEN{
    player_id: "player_id_n",
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

    player_id: "player_id_1",
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

    samples = [sample_n, sample_1]
    players_id = for x <- samples, do: x.fe_struct.player_id

    %{samples: samples, players_id: players_id}
  end

  setup do
    {port, ref} = Medusa.Port.open(System.get_env("MITRAVIAN__MEDUSA_MODELDIR", "priv"))
    on_exit(fn -> Medusa.Port.close(port, ref) end)
    %{port: port, ref: ref}
  end


  test "Predictions has the same length as input", %{port: port, samples: samples} do
    predictions = Medusa.Port.predict!(port, samples)
    assert(length(predictions) == length(samples))
  end

  test "players_id has to be keep in predictions", %{port: port, samples: samples, players_id: players_id} do
    predictions = Medusa.Port.predict!(port, samples)
    pred_players_id = Enum.map(predictions, fn x -> x.player_id end)
    |> Enum.sort()
    |> Enum.uniq()

    sorted_players_id = Enum.sort(players_id)
    assert(sorted_players_id == pred_players_id)
  end

  test "Predictions should be model, bool and probability", %{port: port, samples: samples} do
    predictions = Medusa.Port.predict!(port, samples)
    for pred <- predictions, do: assert_pred(pred)
  end


  test "Predict 2 times with the same port doesn't break it", %{port: port, samples: samples} do
    _ = Medusa.Port.predict!(port, samples)
    _ = Medusa.Port.predict!(port, samples)
  end


  test "Predict an [] shuld return []", %{port: port} do
    assert([] == Medusa.Port.predict!(port, []))
  end


  defp assert_pred(pred) do
    assert(is_struct(pred, Medusa.Port))
    assert(pred.model == :player_n or pred.model == :player_1)
    assert(is_boolean(pred.inactive_in_future))
    assert(pred.inactive_probability >= 0 and pred.inactive_probability <= 1)
    case pred.inactive_probability do
      x when x >= 0.5 -> assert(pred.inactive_in_future == true)
      _x -> assert(pred.inactive_in_future == false)
    end
  end
end
