defmodule StorageTest do
  use ExUnit.Case
  doctest Storage


  @tag :tmp_dir
  test "if there is no info stored, fetch_last_info should return {:ok, :no_files}", %{tmp_dir: tmp_dir} do
    root_folder = tmp_dir
    server_id = "https://ts8.x1.europe.travian.com"
    assert(Storage.fetch_last_info(root_folder, server_id) == {:ok, :no_files})
  end


  @tag :tmp_dir
  test "If only one info stored, fetch_last_info should return it", %{tmp_dir: tmp_dir} do
    root_folder = tmp_dir
    server_id = "https://ts8.x1.europe.travian.com"
    info = %{"speed" => "3", "some_value" => "<3"}
    date = DateTime.now!("Etc/UTC") |> DateTime.to_date()
    assert(:ok = Storage.store_info(root_folder, server_id, date, info))
    assert(Storage.fetch_last_info(root_folder, server_id) == {:ok, info})
  end


  @tag :tmp_dir
  test "fetch_last_info return the newest info", %{tmp_dir: tmp_dir} do
    root_folder = tmp_dir
    server_id = "https://ts8.x1.europe.travian.com"
    info1 = %{"speed" => "3", "some_value" => "<1"}
    info2 = %{"speed" => "3", "some_value" => "<2"}
    info3 = %{"speed" => "3", "some_value" => "<3"}
    date1 = DateTime.now!("Etc/UTC") |> DateTime.to_date()
    date2 = Date.add(date1, 7)
    date3 = Date.add(date1, 1)
    assert(:ok = Storage.store_info(root_folder, server_id, date1, info1))
    assert(:ok = Storage.store_info(root_folder, server_id, date2, info2))
    assert(:ok = Storage.store_info(root_folder, server_id, date3, info3))
    assert(Storage.fetch_last_info(root_folder, server_id) == {:ok, info2})
  end


  @tag :tmp_dir
  test "if there is no snapthot stored, fetch_last_n_snapshots should return {:ok, []}", %{tmp_dir: tmp_dir} do
    root_folder = tmp_dir
    server_id = "https://ts8.x1.europe.travian.com"
    n = 3
    assert(Storage.fetch_last_n_snapshots(root_folder, server_id, n) == {:ok, []})
  end


  @tag :tmp_dir
  test "fetch_last_n_snapshots get last n snapshots", %{tmp_dir: tmp_dir} do
    snapshot_1 = [%{
		     alliance_id: "https://ts8.x1.europe.travian.com--A--44",
		     alliance_name: "TOP+",
		     grid_position: 15,
		     player_id: "https://ts8.x1.europe.travian.com--P--14630",
		     player_name: "Tierwelt",
		     population: 47,
		     region: nil,
		     tribe: 3,
		     undef_1: false,
		     undef_2: nil,
		     victory_points: nil,
		     village_id: "https://ts8.x1.europe.travian.com--V--74847",
		     village_name: "Neues Dorf",
		     x: -186,
		     y: 200
		  },
		  %{
		    alliance_id: "https://ts8.x1.europe.travian.com--A--46",
		    alliance_name: "GW",
		    grid_position: 29,
		    player_id: "https://ts8.x1.europe.travian.com--P--4080",
		    player_name: "Barabbas",
		    population: 853,
		    region: nil,
		    tribe: 1,
		    undef_1: false,
		    undef_2: nil,
		    victory_points: nil,
		    village_id: "https://ts8.x1.europe.travian.com--V--44259",
		    village_name: "05",
		    x: -172,
		    y: 200
		  }]


    snapshot_2 = [%{
		     alliance_id: "https://ts8.x1.europe.travian.com--A--44",
		     alliance_name: "TOP+",
		     grid_position: 15,
		     player_id: "https://ts8.x1.europe.travian.com--P--14630",
		     player_name: "Tierwelt",
		     population: 49,
		     region: nil,
		     tribe: 3,
		     undef_1: false,
		     undef_2: nil,
		     victory_points: nil,
		     village_id: "https://ts8.x1.europe.travian.com--V--74847",
		     village_name: "Neues Dorf",
		     x: -186,
		     y: 200
		  },
		  %{
		    alliance_id: "https://ts8.x1.europe.travian.com--A--46",
		    alliance_name: "GW",
		    grid_position: 29,
		    player_id: "https://ts8.x1.europe.travian.com--P--4080",
		    player_name: "Barabbas",
		    population: 853,
		    region: nil,
		    tribe: 1,
		    undef_1: false,
		    undef_2: nil,
		    victory_points: nil,
		    village_id: "https://ts8.x1.europe.travian.com--V--44259",
		    village_name: "05",
		    x: -172,
		    y: 200
		  }]


    snapshot_3 = [%{
		     alliance_id: "https://ts8.x1.europe.travian.com--A--44",
		     alliance_name: "TOP+",
		     grid_position: 15,
		     player_id: "https://ts8.x1.europe.travian.com--P--14630",
		     player_name: "Tierwelt",
		     population: 60,
		     region: nil,
		     tribe: 3,
		     undef_1: false,
		     undef_2: nil,
		     victory_points: nil,
		     village_id: "https://ts8.x1.europe.travian.com--V--74847",
		     village_name: "Neues Dorf",
		     x: -186,
		     y: 200
		  },
		  %{
		    alliance_id: "https://ts8.x1.europe.travian.com--A--46",
		    alliance_name: "GW",
		    grid_position: 29,
		    player_id: "https://ts8.x1.europe.travian.com--P--4080",
		    player_name: "Barabbas",
		    population: 853,
		    region: nil,
		    tribe: 1,
		    undef_1: false,
		    undef_2: nil,
		    victory_points: nil,
		    village_id: "https://ts8.x1.europe.travian.com--V--44259",
		    village_name: "05",
		    x: -172,
		    y: 200
		  }]

    snapshot_4 = [%{
		     alliance_id: "https://ts8.x1.europe.travian.com--A--44",
		     alliance_name: "TOP+",
		     grid_position: 15,
		     player_id: "https://ts8.x1.europe.travian.com--P--14630",
		     player_name: "Tierwelt",
		     population: 60,
		     region: nil,
		     tribe: 3,
		     undef_1: false,
		     undef_2: nil,
		     victory_points: nil,
		     village_id: "https://ts8.x1.europe.travian.com--V--74847",
		     village_name: "Neues Dorf",
		     x: -186,
		     y: 200
		  },
		  %{
		    alliance_id: "https://ts8.x1.europe.travian.com--A--46",
		    alliance_name: "GW",
		    grid_position: 29,
		    player_id: "https://ts8.x1.europe.travian.com--P--4080",
		    player_name: "Barabbas",
		    population: 853,
		    region: nil,
		    tribe: 1,
		    undef_1: false,
		    undef_2: nil,
		    victory_points: nil,
		    village_id: "https://ts8.x1.europe.travian.com--V--44259",
		    village_name: "05",
		    x: -172,
		    y: 200
		  }]

    inserts = [
      {~D[2022-04-14], snapshot_1},
      {~D[2022-04-15], snapshot_2},
      {~D[2022-04-17], snapshot_4},
      {~D[2022-04-16], snapshot_3}
    ]

    output = [
      {~D[2022-04-17], snapshot_4},
      {~D[2022-04-16], snapshot_3}
    ]


    root_folder = tmp_dir
    server_id = "https://ts8.x1.europe.travian.com"
    n = 2


    for {date, snap} <- inserts, do: assert(Storage.store_snapshot(root_folder, server_id, date, snap) == :ok)
    assert(Storage.fetch_last_n_snapshots(root_folder, server_id, n) == {:ok, output})
  end



  @tag :tmp_dir
  test "fetch_last_n_snapshots gets j if j < n snapshots", %{tmp_dir: tmp_dir} do
    snapshot_1 = [%{
		     alliance_id: "https://ts8.x1.europe.travian.com--A--44",
		     alliance_name: "TOP+",
		     grid_position: 15,
		     player_id: "https://ts8.x1.europe.travian.com--P--14630",
		     player_name: "Tierwelt",
		     population: 47,
		     region: nil,
		     tribe: 3,
		     undef_1: false,
		     undef_2: nil,
		     victory_points: nil,
		     village_id: "https://ts8.x1.europe.travian.com--V--74847",
		     village_name: "Neues Dorf",
		     x: -186,
		     y: 200
		  },
		  %{
		    alliance_id: "https://ts8.x1.europe.travian.com--A--46",
		    alliance_name: "GW",
		    grid_position: 29,
		    player_id: "https://ts8.x1.europe.travian.com--P--4080",
		    player_name: "Barabbas",
		    population: 853,
		    region: nil,
		    tribe: 1,
		    undef_1: false,
		    undef_2: nil,
		    victory_points: nil,
		    village_id: "https://ts8.x1.europe.travian.com--V--44259",
		    village_name: "05",
		    x: -172,
		    y: 200
		  }]


    snapshot_2 = [%{
		     alliance_id: "https://ts8.x1.europe.travian.com--A--44",
		     alliance_name: "TOP+",
		     grid_position: 15,
		     player_id: "https://ts8.x1.europe.travian.com--P--14630",
		     player_name: "Tierwelt",
		     population: 49,
		     region: nil,
		     tribe: 3,
		     undef_1: false,
		     undef_2: nil,
		     victory_points: nil,
		     village_id: "https://ts8.x1.europe.travian.com--V--74847",
		     village_name: "Neues Dorf",
		     x: -186,
		     y: 200
		  },
		  %{
		    alliance_id: "https://ts8.x1.europe.travian.com--A--46",
		    alliance_name: "GW",
		    grid_position: 29,
		    player_id: "https://ts8.x1.europe.travian.com--P--4080",
		    player_name: "Barabbas",
		    population: 853,
		    region: nil,
		    tribe: 1,
		    undef_1: false,
		    undef_2: nil,
		    victory_points: nil,
		    village_id: "https://ts8.x1.europe.travian.com--V--44259",
		    village_name: "05",
		    x: -172,
		    y: 200
		  }]

    inserts = [
      {~D[2022-04-14], snapshot_1},
      {~D[2022-04-15], snapshot_2}
    ]

    output = [
      {~D[2022-04-15], snapshot_2},
      {~D[2022-04-14], snapshot_1}
    ]


    root_folder = tmp_dir
    server_id = "https://ts8.x1.europe.travian.com"
    n = 3


    for {date, snap} <- inserts, do: assert(Storage.store_snapshot(root_folder, server_id, date, snap) == :ok)
    assert(Storage.fetch_last_n_snapshots(root_folder, server_id, n) == {:ok, output})
  end


end
