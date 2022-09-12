defmodule MedusaMetricsTest do
  use ExUnit.Case
  doctest MedusaMetrics

  setup do

    server_id = "https://ts6.x1.europe.travian.com"
    
    new = [
      %Satellite.MedusaTable{
	alliance_id: "https://ts6.x1.europe.travian.com--A--122",
	alliance_name: "TLB",
	alliance_url: "TLB",
	creation_dt: ~U[2022-08-28 16:30:45.212454Z],
	inactive_in_current: false,
	inactive_in_future: true,
	model: :player_1,
	n_villages: 8,
	player_id: "https://ts6.x1.europe.travian.com--P--10000",
	player_name: "FemeieDeCasa",
	player_url: "https://ts6.x1.europe.travian.com--P--10000",
	server_id: "https://ts6.x1.europe.travian.com",
	server_url: "https://ts6.x1.europe.travian.com",
	target_date: ~D[2022-08-28],
	total_population: 5280
      },
      %Satellite.MedusaTable{
	alliance_id: "https://ts6.x1.europe.travian.com--A--0",
	alliance_name: "",
	alliance_url: "",
	creation_dt: ~U[2022-08-28 16:30:45.212454Z],
	inactive_in_current: :undefined,
	inactive_in_future: true,
	model: :player_1,
	n_villages: 1290,
	player_id: "https://ts6.x1.europe.travian.com--P--1",
	player_name: "Natars",
	player_url: "https://ts6.x1.europe.travian.com--P--1",
	server_id: "https://ts6.x1.europe.travian.com",
	server_url: "https://ts6.x1.europe.travian.com",
	target_date: ~D[2022-08-28],
	total_population: 246201
      },
      %Satellite.MedusaTable{
	alliance_id: "https://ts6.x1.europe.travian.com--A--105",
	alliance_name: "TÜRK",
	alliance_url: "TÜRK",
	creation_dt: ~U[2022-08-28 16:30:45.212454Z],
	inactive_in_current: true,
	inactive_in_future: true,
	model: :player_1,
	n_villages: 5,
	player_id: "https://ts6.x1.europe.travian.com--P--10003",
	player_name: "Tp34",
	player_url: "https://ts6.x1.europe.travian.com--P--10003", 
	server_id: "https://ts6.x1.europe.travian.com",
	server_url: "https://ts6.x1.europe.travian.com",
	target_date: ~D[2022-08-28],
	total_population: 3048
      },
      %Satellite.MedusaTable{
	alliance_id: "https://ts6.x1.europe.travian.com--A--122",
	alliance_name: "TLB",
	alliance_url: "TLB",
	creation_dt: ~U[2022-08-28 16:30:45.212454Z],
	inactive_in_current: false,
	inactive_in_future: true,
	model: :player_n,
	n_villages: 8,
	player_id: "player_id",
	player_name: "player_name",
	player_url: "https://ts6.x1.europe.travian.com--P--10000",
	server_id: "https://ts6.x1.europe.travian.com",
	server_url: "https://ts6.x1.europe.travian.com",
	target_date: ~D[2022-08-28],
	total_population: 5280
      }
    ]



    older = [

      %Satellite.MedusaTable{
	alliance_id: "https://ts6.x1.europe.travian.com--A--122",
	alliance_name: "TLB",
	alliance_url: "TLB",
	creation_dt: ~U[2022-08-28 16:30:45.212454Z],
	inactive_in_current: false,
	inactive_in_future: true,
	model: :player_n,
	n_villages: 8,
	player_id: "player_id",
	player_name: "player_name",
	player_url: "https://ts6.x1.europe.travian.com--P--10000",
	server_id: "https://ts6.x1.europe.travian.com",
	server_url: "https://ts6.x1.europe.travian.com",
	target_date: ~D[2022-08-27],
	total_population: 5280
      },

      %Satellite.MedusaTable{
	alliance_id: "https://ts6.x1.europe.travian.com--A--122",
	alliance_name: "TLB",
	alliance_url: "TLB",
	creation_dt: ~U[2022-08-28 16:30:45.212454Z],
	inactive_in_current: :undefined,
	inactive_in_future: true,
	model: :player_1,
	n_villages: 8,
	player_id: "https://ts6.x1.europe.travian.com--P--10000",
	player_name: "FemeieDeCasa",
	player_url: "https://ts6.x1.europe.travian.com--P--10000",
	server_id: "https://ts6.x1.europe.travian.com",
	server_url: "https://ts6.x1.europe.travian.com",
	target_date: ~D[2022-08-27],
	total_population: 5280
      },
      %Satellite.MedusaTable{
	alliance_id: "https://ts6.x1.europe.travian.com--A--0",
	alliance_name: "",
	alliance_url: "",
	creation_dt: ~U[2022-08-28 16:30:45.212454Z],
	inactive_in_current: :undefined,
	inactive_in_future: true,
	model: :player_1,
	n_villages: 1,
	player_id: "https://ts6.x1.europe.travian.com--P--1000",
	player_name: "jaisyloo",
	player_url: "https://ts6.x1.europe.travian.com--P--1000",
	server_id: "https://ts6.x1.europe.travian.com",
	server_url: "https://ts6.x1.europe.travian.com",
	target_date: ~D[2022-08-27],
	total_population: 104
      },
      %Satellite.MedusaTable{
	alliance_id: "https://ts6.x1.europe.travian.com--A--105",
	alliance_name: "TÜRK",
	alliance_url: "TÜRK",
	creation_dt: ~U[2022-08-28 16:30:45.212454Z],
	inactive_in_current: :undefined,
	inactive_in_future: true,
	model: :player_1,
	n_villages: 5,
	player_id: "https://ts6.x1.europe.travian.com--P--10003",
	player_name: "Tp34",
	player_url: "https://ts6.x1.europe.travian.com--P--10003", 
	server_id: "https://ts6.x1.europe.travian.com",
	server_url: "https://ts6.x1.europe.travian.com",
	target_date: ~D[2022-08-27],
	total_population: 3048
      }]




    expected_failed = [
      %MedusaMetrics.Failed{expected: true, model: :player_n, old_date: ~D[2022-08-26], player_id: "player_id", result: false, server_id: "https://ts6.x1.europe.travian.com", target_date: ~D[2022-08-28]},
      %MedusaMetrics.Failed{server_id: server_id, player_id: "https://ts6.x1.europe.travian.com--P--10000", model: :player_1, target_date: ~D[2022-08-28], old_date: ~D[2022-08-26], expected: true, result: false}
    ]

    expected_metrics = %MedusaMetrics.Metrics{
      total_players: 3,
      failed_players: 2,
      models: %{
	player_n: %MedusaMetrics.Models{failed_players: 1, model: :player_n, total_players: 1},
	player_1: %MedusaMetrics.Models{model: :player_1, total_players: 2, failed_players: 1}
      },
      target_date: ~D[2022-08-28],
      old_date: ~D[2022-08-26]
    }




    %{server_id: server_id, older: older, new: new, expected_failed: expected_failed, expected_metrics: expected_metrics}
end



  @tag :tmp_dir
  test "et outputs {:error, old_file} when old file is missing", %{server_id: si, tmp_dir: root_folder, new: n} do
    today = Date.utc_today()
    yesterday = Date.utc_today() |> Date.add(-1)
    :ok = Storage.store(root_folder, si, Medusa.predictions_options(), Medusa.predictions_to_format(n))

    {:error, {error, reason}} = MedusaMetrics.et(root_folder, si, today, yesterday)
    assert(error == "failed while reading old_file")
  end

  @tag :tmp_dir
  test "et outputs {:error, target_file} when target file is missing", %{server_id: si, tmp_dir: root_folder, new: n} do
    today = Date.utc_today()
    yesterday = Date.utc_today() |> Date.add(-1)
    :ok = Storage.store(root_folder, si, Medusa.predictions_options(), Medusa.predictions_to_format(n), yesterday)

    {:error, {error, reason}} = MedusaMetrics.et(root_folder, si, today, yesterday)
    assert(error == "failed while reading target_file")
  end

  @tag :tmp_dir
  test "et only returns players and metrics that are common in both days", %{server_id: si, tmp_dir: root_folder, older: o, new: n, expected_failed: ef, expected_metrics: em} do
    today = ~D[2022-08-28]
    yesterday2 = today |> Date.add(-2)
    :ok = Storage.store(root_folder, si, Medusa.predictions_options(), Medusa.predictions_to_format(n), today)
    :ok = Storage.store(root_folder, si, Medusa.predictions_options(), Medusa.predictions_to_format(o), yesterday2)

    assert({:ok, {em, ef}} == MedusaMetrics.et(root_folder, si, today, yesterday2))
  end

end
