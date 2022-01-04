defmodule ProcessTravianmapTest do
  use ExUnit.Case

  # test "process server data" do
  #   server_id = "server_id"
  #   url = "url"
  #   init_date = ~U[2018-11-15 11:00:00Z]
  #   server_info = %{}
  #   output = Collector.ProcessTravianMap.process_server(server_id, url, init_date, server_info)

  #   assert
  # end



  test "travian tuple to map" do
    input = {406, -196, 199, 3, 21566, "Coruscant", 3896, "tiwi", 0, "", 525}
    output = %{
      :grid_position => 406,
      :x_position => -196,
      :y_position => 199,
      :tribe => 3,
      :village_id => 21566,
      :village_name => "Coruscant",
      :player_id => 3896,
      :player_name => "tiwi",
      :alliance_id => 0,
      :alliance_name => "",
      :population => 525
    }

    assert(output == Collector.ProcessTravianMap.tuple_to_map(input), "Bad map translation")
  end



  test "process players" do
    input = [%{
      alliance_id: 0,
      alliance_name: "",
      grid_position: 406,
      player_id: 3896,
      player_name: "tiwi",
      population: 525,
      tribe: 3,
      village_id: 21566,
      village_name: "Coruscant",
      x_position: -196,
      y_position: 199}]

    server_id = Collector.ProcessTravianMap.create_server_id("some_url", ~U[2018-11-15 11:00:00Z])
    [output] = Collector.ProcessTravianMap.process_players(server_id, input)

    assert(output.data.server_id == server_id, "Bad server_id")
    assert(output.data.id == server_id <> "--P3896", "Bad player_id")
    assert(output.data.game_id == 3896, "Bad player_game_id")
    assert(output.valid?, "Invalid changeset")
  end

  test "process alliance" do
    input = [%{
      alliance_id: 0,
      alliance_name: "",
      grid_position: 406,
      player_id: 3896,
      player_name: "tiwi",
      population: 525,
      tribe: 3,
      village_id: 21566,
      village_name: "Coruscant",
      x_position: -196,
      y_position: 199}]

    server_id = Collector.ProcessTravianMap.create_server_id("some_url", ~U[2018-11-15 11:00:00Z])
    [output] = Collector.ProcessTravianMap.process_alliances(server_id, input)

    assert(output.data.server_id == server_id, "Bad server_id")
    assert(output.data.id == server_id <> "--A0", "Bad alliance_id")
    assert(output.data.game_id == 0, "Bad alliance_game_id")
    assert(output.valid?, "Invalid changeset")
  end


  test "process village" do
    input = [%{
      alliance_id: 0,
      alliance_name: "",
      grid_position: 406,
      player_id: 3896,
      player_name: "tiwi",
      population: 525,
      tribe: 3,
      village_id: 21566,
      village_name: "Coruscant",
      x_position: -196,
      y_position: 199}]

    server_id = Collector.ProcessTravianMap.create_server_id("some_url", ~U[2018-11-15 11:00:00Z])
    [output] = Collector.ProcessTravianMap.process_villages(server_id, input)

    assert(output.data.server_id == server_id, "Bad server_id")
    assert(output.data.id == server_id <> "--V21566", "Bad village_id")
    assert(output.data.game_id == 21566, "Bad village_game_id")
    assert(output.valid?, "Invalid changeset")
  end


  test "process alliance - player" do
    input = [%{
      alliance_id: 0,
      alliance_name: "",
      grid_position: 406,
      player_id: 3896,
      player_name: "tiwi",
      population: 525,
      tribe: 3,
      village_id: 21566,
      village_name: "Coruscant",
      x_position: -196,
      y_position: 199}]

    server_id = Collector.ProcessTravianMap.create_server_id("some_url", ~U[2018-11-15 11:00:00Z])
    [output] = Collector.ProcessTravianMap.process_a_ps(server_id, input)


    assert(output.data.alliance_id == server_id <> "--A0", "Bad alliance_id")
    assert(output.data.player_id == server_id <> "--P3896", "Bad player_id")
    assert(output.valid?, "Invalid changeset")
  end


  test "process player - village" do
    input = [%{
      alliance_id: 0,
      alliance_name: "",
      grid_position: 406,
      player_id: 3896,
      player_name: "tiwi",
      population: 525,
      tribe: 3,
      village_id: 21566,
      village_name: "Coruscant",
      x_position: -196,
      y_position: 199}]

    server_id = Collector.ProcessTravianMap.create_server_id("some_url", ~U[2018-11-15 11:00:00Z])
    [output] = Collector.ProcessTravianMap.process_p_vs(server_id, input)


    assert(output.data.player_id == server_id <> "--P3896", "Bad player_id")
    assert(output.data.village_id == server_id <> "--V21566", "Bad village_id")
    assert(output.data.population == 525, "Bad population")
    assert(output.data.race == 3, "Bad tribe")
    assert(output.valid?, "Invalid changeset")
  end

  test "process server" do
    url = "some_url"
    init_date = ~U[2018-11-15 11:00:00Z]
    aditional_info = %{"speed" => 1}
    server_id = Collector.ProcessTravianMap.create_server_id(url, init_date)
    output = Collector.ProcessTravianMap.process_server(server_id, url, init_date, aditional_info)

    assert(output.data.id == server_id, "Bad server_id")
    assert(output.data.url == url, "Bad url")
    assert(output.data.init_date == ~D[2018-11-15], "Bad init_date")
    assert(output.valid?, "Invalid changeset")
  end

end
