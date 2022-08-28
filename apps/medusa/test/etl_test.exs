defmodule Medusa.ETLTest do
  use ExUnit.Case


  @snapshot_options {"snapshot", ".c6bert"}
  @predictions_options {"medusa_predictions", ".c6bert"}
  
  setup do
    
    today = Date.utc_today()
    yesterday = Date.add(today, -1)
    server_id = "https://czsk.x1.czsk.travian.com"
    model_dir = "/home/jorge/Proyectos/my_travian/apps/medusa/priv/"

    {:ok, port} = Medusa.GenPort.start_link(model_dir)


    
    snp_today = [
	%Collector.SnapshotRow{
	  alliance_id: "https://czsk.x1.czsk.travian.com--A--26",
	  alliance_name: "ZBL",
	  grid_position: 1,
	  is_capital: false,
	  is_city: nil,
	  player_id: "https://czsk.x1.czsk.travian.com--P--815",
	  player_name: "Klobuk",
	  population: 624,
	  region: nil,
	  tribe: 1,
	  victory_points: nil,
	  village_id: "https://czsk.x1.czsk.travian.com--V--21796",
	  village_name: "P Štiavnik",
	  x: -200,
	  y: 200
},
	%Collector.SnapshotRow{
	  alliance_id: "https://czsk.x1.czsk.travian.com--A--26",
	  alliance_name: "ZBL",
	  grid_position: 2,
	  is_capital: true,
	  is_city: nil,
	  player_id: "https://czsk.x1.czsk.travian.com--P--815",
	  player_name: "Klobuk",
	  population: 945,
	  region: nil,
	  tribe: 1,
	  victory_points: nil,
	  village_id: "https://czsk.x1.czsk.travian.com--V--20756",
	  village_name: "J Hliník nad Váhom",
	  x: -199,
	  y: 200
	},
	%Collector.SnapshotRow{
	  alliance_id: "https://czsk.x1.czsk.travian.com--A--18",
	  alliance_name: "00A",
	  grid_position: 73,
	  is_capital: false,
	  is_city: nil,
	  player_id: "https://czsk.x1.czsk.travian.com--P--1009",
	  player_name: "PalMer",
	  population: 207,
	  region: nil,
	  tribe: 3,
	  victory_points: nil,
	  village_id: "https://czsk.x1.czsk.travian.com--V--25494",
	  village_name: "Ellie",
	  x: -128,
	  y: 200
	},
	%Collector.SnapshotRow{
	  alliance_id: "https://czsk.x1.czsk.travian.com--A--26",
	  alliance_name: "ZBL",
	  grid_position: 403,
	  is_capital: false,
	  is_city: nil,
	  player_id: "https://czsk.x1.czsk.travian.com--P--815",
	  player_name: "Klobuk",
	  population: 51,
	  region: nil,
	  tribe: 1,
	  victory_points: nil,
	  village_id: "https://czsk.x1.czsk.travian.com--V--26116",
	  village_name: "Nová Dedina",
	  x: -199,
	  y: 199
	}
      ]
    
    snp_yesterday = [
      %Collector.SnapshotRow{
	alliance_id: "https://czsk.x1.czsk.travian.com--A--26",
	alliance_name: "ZBL",
	grid_position: 1,
	is_capital: false,
	is_city: nil,
	player_id: "https://czsk.x1.czsk.travian.com--P--815",
	player_name: "Klobuk",
	population: 624,
	region: nil,
	tribe: 1,
	victory_points: nil,
	village_id: "https://czsk.x1.czsk.travian.com--V--21796",
	village_name: "P Štiavnik",
	x: -200,
	y: 200
},
      
      %Collector.SnapshotRow{
	alliance_id: "https://czsk.x1.czsk.travian.com--A--18",
	alliance_name: "00A",
	grid_position: 73,
	is_capital: false,
	is_city: nil,
	player_id: "https://czsk.x1.czsk.travian.com--P--1009",
	player_name: "PalMer",
	population: 227,
	region: nil,
	tribe: 3,
	victory_points: nil,
	village_id: "https://czsk.x1.czsk.travian.com--V--25494",
	village_name: "Ellie",
	x: -128,
	y: 200
      },
      
      
      %Collector.SnapshotRow{
	alliance_id: "https://czsk.x1.czsk.travian.com--A--26",
	alliance_name: "ZBL",
	grid_position: 2,
	is_capital: true,
	is_city: nil,
	player_id: "https://czsk.x1.czsk.travian.com--P--815",
	player_name: "Klobuk",
	population: 845,
	region: nil,
	tribe: 1,
	victory_points: nil,
	village_id: "https://czsk.x1.czsk.travian.com--V--20756",
	village_name: "J Hliník nad Váhom",
	x: -199,
	y: 200
      }
    ]

    # on_exit(fn -> Medusa.GenPort.stop(port) end)
    %{snp_today: snp_today, snp_yesterday: snp_yesterday, port: port, server_id: server_id, td: today, yes: yesterday}
  end
  
  @tag :tmp_dir
  test "Medusa.etl fetch snapshots, make the predictions and store it", %{snp_today: snp_today, snp_yesterday: snp_yesterday, port: port, server_id: server_id, tmp_dir: root_folder, td: td, yes: yes} do

    :ok == Storage.store(root_folder, server_id, @snapshot_options, Collector.snapshot_to_format(snp_today), td)
    :ok == Storage.store(root_folder, server_id, @snapshot_options, Collector.snapshot_to_format(snp_yesterday), yes)


    expected_output = [
    %Satellite.MedusaTable{alliance_id: "https://czsk.x1.czsk.travian.com--A--18",
      alliance_name: "00A",
      alliance_url: "00A",
      inactive_in_current: true,
      inactive_in_future: true,
      model: :player_n,
      n_villages: 1,
      player_id: "https://czsk.x1.czsk.travian.com--P--1009",
      player_name: "PalMer",
      player_url: "https://czsk.x1.czsk.travian.com--P--1009",
			   total_population: 207,
			     creation_dt: nil,
			   target_date: td
			  },

      %Satellite.MedusaTable{alliance_id: "https://czsk.x1.czsk.travian.com--A--26",
	alliance_name: "ZBL",
	alliance_url: "ZBL",
	inactive_in_current: false,
	inactive_in_future: true,
	model: :player_n,
	n_villages: 3,
	player_id: "https://czsk.x1.czsk.travian.com--P--815",
	player_name: "Klobuk",
	player_url: "https://czsk.x1.czsk.travian.com--P--815",

			     target_date: td,
			     creation_dt: nil,
	total_population: 1620}]


    {:ok, output} = Medusa.etl(root_folder, port, server_id)
    assert(expected_output == set_creation_dt_to_nil(output))

    Medusa.GenPort.stop(port)
    {:ok, {^td, encoded_predictions}} = Storage.open(root_folder, server_id, @predictions_options, td)
    assert(output == Medusa.predictions_from_format(encoded_predictions))

  end
  
  
  @tag :tmp_dir
  test "if thre is only one snapshot, it will apply the 1 day model and inactive_in_current: :undefined", %{snp_yesterday: snp_yesterday, port: port, server_id: server_id, tmp_dir: root_folder, yes: yes} do

    :ok == Storage.store(root_folder, server_id, @snapshot_options, Collector.snapshot_to_format(snp_yesterday), yes)

    expected_output = [%Satellite.MedusaTable{alliance_id: "https://czsk.x1.czsk.travian.com--A--18",
		alliance_name: "00A",
		alliance_url: "00A",
		inactive_in_current: :undefined,
		inactive_in_future: true,
		model: :player_1,
		n_villages: 1,
		player_id: "https://czsk.x1.czsk.travian.com--P--1009",
		player_name: "PalMer",
		player_url: "https://czsk.x1.czsk.travian.com--P--1009",
			     target_date: yes,
			     creation_dt: nil,
		total_population: 227},
	      
              %Satellite.MedusaTable{alliance_id: "https://czsk.x1.czsk.travian.com--A--26",
		alliance_name: "ZBL",
		alliance_url: "ZBL",
		inactive_in_current: :undefined,
		inactive_in_future: true,
		model: :player_1,
		n_villages: 2,
		player_id: "https://czsk.x1.czsk.travian.com--P--815",
		player_name: "Klobuk",
		player_url: "https://czsk.x1.czsk.travian.com--P--815",
			     target_date: yes,
			     creation_dt: nil,
		total_population: 1469}]

    


    {:ok, output} = Medusa.etl(root_folder, port, server_id, yes)
    assert(expected_output == set_creation_dt_to_nil(output))

    Medusa.GenPort.stop(port)
    {:ok, {^yes, encoded_predictions}} = Storage.open(root_folder, server_id, @predictions_options, yes)
    assert(output == Medusa.predictions_from_format(encoded_predictions))
  end


  defp set_creation_dt_to_nil(medusa_structs) do
    for ms <- medusa_structs, do: Map.put(ms, :creation_dt, nil)
  end
  
end
