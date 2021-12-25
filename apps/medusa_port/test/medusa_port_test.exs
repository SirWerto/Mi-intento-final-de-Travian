defmodule MedusaPortTest do
  use ExUnit.Case
  doctest MedusaPort

  test "load good model" do
    models_dir = System.get_env("MEDUSA_MODEL_DIR")
    {port, _ref} = MedusaPort.open_port(models_dir <> "/medusa_model")
    true = MedusaPort.load_model(port)
    assert_receive({^port, {:data, "\"loaded\""}}, 2000, "not loaded")
  end

  test "eval players" do
    players = [
      %{
	end_population: 217,
	last_day: -0.9837979515735163,
	max_races: 1,
	player_id: "player_inactive",
	pop_increase_day_1: 0,
	pop_increase_day_2: 0,
	pop_increase_day_3: 0,
	pop_increase_day_4: 0,
	total_decrease: -12,
	weekend?: false
      },
      
      %{
	end_population: 417,
	last_day: -0.9837979515735163,
	max_races: 1,
	player_id: "player_active",
	pop_increase_day_1: 30,
	pop_increase_day_2: 2,
	pop_increase_day_3: 21,
	pop_increase_day_4: 30,
	total_decrease: -12,
	weekend?: false
      }
    ]


    models_dir = System.get_env("MEDUSA_MODEL_DIR")
    {port, _ref} = MedusaPort.open_port(models_dir <> "/medusa_model")
    true = MedusaPort.load_model(port)
    true = MedusaPort.send_players(players, port)

    answer = {:data, "[\"predicted\", {\"player_inactive\": \"inactive\", \"player_active\": \"active\"}]"}
    assert_receive({^port, ^answer}, 2000, "not evaluated")
  end
end
