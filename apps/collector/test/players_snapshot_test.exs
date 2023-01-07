defmodule PlayersSnapshotTest do
  use ExUnit.Case


test "PlayersSnapshot.group group all the enriched_rows by player and adds extra fields" do
  input = [
    %Collector.SnapshotRow{
      grid_position: 20,
      x: -181,
      y: 200,
      tribe: 2,
      village_id: "https://schild.x1.travian.com--V--19995",
      village_server_id: 19995,
      village_name: "wodka 2",
      player_id: "https://schild.x1.travian.com--P--361",
      player_server_id: 361,
      player_name: "opc",
      alliance_id: "https://schild.x1.travian.com--A--8",
      alliance_server_id: 8,
      alliance_name: "WW",
      population: 961,
      region: nil,
      is_capital: false,
      is_city: nil,
      victory_points: nil
    },
    %Collector.SnapshotRow{
      grid_position: 49,
      x: -152,
      y: 200,
      tribe: 1,
      village_id: "https://schild.x1.travian.com--V--19702",
      village_server_id: 19702,
      village_name: "Hongkong",
      player_id: "https://schild.x1.travian.com--P--416",
      player_server_id: 416,
      player_name: "Lolhannes",
      alliance_id: "https://schild.x1.travian.com--A--8",
      alliance_server_id: 8,
      alliance_name: "WW",
      population: 964,
      region: nil,
      is_capital: false,
      is_city: nil,
      victory_points: nil
    },
    %Collector.SnapshotRow{
      grid_position: 30,
      x: -151,
      y: 180,
      tribe: 3,
      village_id: "https://schild.x1.travian.com--V--19996",
      village_server_id: 19996,
      village_name: "wodka 3",
      player_id: "https://schild.x1.travian.com--P--361",
      player_server_id: 361,
      player_name: "opc",
      alliance_id: "https://schild.x1.travian.com--A--8",
      alliance_server_id: 8,
      alliance_name: "WW",
      population: 1200,
      region: nil,
      is_capital: false,
      is_city: nil,
      victory_points: nil
    }
  ]

  expected_output = [
    %Collector.PlayersSnapshot{
      player_id: "https://schild.x1.travian.com--P--361",
      alliance_id: "https://schild.x1.travian.com--A--8",
      n_villages: 2,
      total_population: 2161,
      villages: [
	%Collector.PlayersSnapshot.Village{
	  village_id: "https://schild.x1.travian.com--V--19996",
	  x: -151,
	  y: 180,
	  population: 1200,
	  tribe: 3,
	  region: nil,
	  is_capital: false,
	  is_city: nil,
	  victory_points: nil},
	%Collector.PlayersSnapshot.Village{
	  village_id: "https://schild.x1.travian.com--V--19995",
	  x: -181,
	  y: 200,
	  population: 961,
	  tribe: 2,
	  region: nil,
	  is_capital: false,
	  is_city: nil,
	  victory_points: nil}
      ]
      |> Enum.sort_by(&(&1.village_id))},
    %Collector.PlayersSnapshot{
      player_id: "https://schild.x1.travian.com--P--416",
      alliance_id: "https://schild.x1.travian.com--A--8",
      n_villages: 1,
      total_population: 964,
      villages: [
	%Collector.PlayersSnapshot.Village{
	  village_id: "https://schild.x1.travian.com--V--19702",
	  x: -152,
	  y: 200,
	  population: 964,
	  tribe: 1,
	  region: nil,
	  is_capital: false,
	  is_city: nil,
	  victory_points: nil},
      ]}
  ]
  |> Enum.sort_by(&(&1.player_id))

  # may require sorting
  output = Collector.PlayersSnapshot.group(input)
    assert expected_output == output

  end
end
