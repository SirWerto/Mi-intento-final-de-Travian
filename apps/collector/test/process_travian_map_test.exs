defmodule ProcessTravianmapTest do
  use ExUnit.Case

  test "normal enriched_map from tuple" do
    server_id = "www.some_server.fr"
    input = {406, -196, 199, 3, 21566, "Coruscant", 3896, "tiwi", 0, "", 525}
    output = %{
      grid_position: 406,
      x: -196,
      y: 199,
      tribe: 3,
      village_id: server_id <> "--V--21566",
      village_name: "Coruscant",
      player_id: server_id <> "--P--3896",
      player_name: "tiwi",
      alliance_id: server_id <> "--A--0",
      alliance_name: "",
      population: 525
    }
    assert output == Collector.ProcessTravianMap.enriched_map(input, server_id)
  end

  test "conquer enriched_map from tuple" do
    server_id = "www.some_server.fr"
    input = {406, -196, 199, 3, 21566, "Coruscant", 3896, "tiwi", 0, "", 525, "Cannes", true, false, 44}
    output = %{
      grid_position: 406,
      x: -196,
      y: 199,
      tribe: 3,
      village_id: server_id <> "--V--21566",
      village_name: "Coruscant",
      player_id: server_id <> "--P--3896",
      player_name: "tiwi",
      alliance_id: server_id <> "--A--0",
      alliance_name: "",
      population: 525,
      region: "Cannes",
      bool1: true,
      bool2: false,
      integer1: 44
    }
    assert output == Collector.ProcessTravianMap.enriched_map(input, server_id)
  end


  test "compare 2 equals servers_info" do
    old_info = %{
      "speed" => 4,
      "another_key" => "some_info"
    }

    new_info = old_info

    assert :not_necessary == Collector.ProcessTravianMap.compare_server_info(old_info, new_info)
  end


  test "compare 2 servers_info with new keys" do
    old_info = %{
      "speed" => 4,
      "another_key" => "some_info"
    }


    new_info = %{
      "conquer" => true
    }

    info_output = %{
      "speed" => 4,
      "another_key" => "some_info",
      "conquer" => true
    }
    assert info_output == Collector.ProcessTravianMap.compare_server_info(old_info, new_info)
  end


  test "compare 2 non_equals servers_info" do
    old_info = %{
      "speed" => 4,
      "another_key" => "some_info"
    }


    new_info = %{
      "speed" => 5
    }

    info_output = %{
      "speed" => 5,
      "another_key" => "some_info"
    }
    assert info_output == Collector.ProcessTravianMap.compare_server_info(old_info, new_info)
  end

end
