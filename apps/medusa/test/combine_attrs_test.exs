defmodule CombineAttrsTest do
  use ExUnit.Case


  test "combine one player" do

    player_id = "player"
    status = "active"
    name = "name"
    alliance_name = "alliance_name"
    n_villages = 1
    total_population = 10


    player = {player_id, status}
    extra_attr = {player_id, name, alliance_name, n_villages, total_population}
    player_output = {player_id, status, name, alliance_name, n_villages, total_population}


    players = [player]
    extra_attrs = [extra_attr]

    assert([player_output] == Medusa.CombineAttrs.combine(players, extra_attrs))
  end


  test "combine multiple with some empty" do

    player_id_1 = "player1"
    status_1 = "active"
    name_1 = "name"
    alliance_name_1 = "alliance_name"
    n_villages_1 = 1
    total_population_1 = 10

    player_id_2 = "player2"
    status_2 = "active"
    name_2 = "name"
    alliance_name_2 = "alliance_name"
    n_villages_2 = 2
    total_population_2 = 20

    player_id_3 = "player3"
    status_3 = "active"
    name_3 = "name"
    alliance_name_3 = "alliance_name"
    n_villages_3 = 3
    total_population_3 = 30

    player_id_4 = "player4"
    status_4 = "active"
    name_4 = "name"
    alliance_name_4 = "alliance_name"
    n_villages_4 = 4
    total_population_4 = 40


    player_1 = {player_id_1, status_1}
    player_2 = {player_id_2, status_2}
    player_3 = {player_id_3, status_3}
    player_4 = {player_id_4, status_4}

    extra_attr_1 = {player_id_1, name_1, alliance_name_1, n_villages_1, total_population_1}
    extra_attr_2 = {player_id_2, name_2, alliance_name_2, n_villages_2, total_population_2}
    extra_attr_4 = {player_id_4, name_4, alliance_name_4, n_villages_4, total_population_4}

    player_output_1 = {player_id_1, status_1, name_1, alliance_name_1, n_villages_1, total_population_1}
    player_output_2 = {player_id_2, status_2, name_2, alliance_name_2, n_villages_2, total_population_2}
    player_output_3 = {player_id_3, status_3, name_3, alliance_name_3, n_villages_3, total_population_3}
    player_output_4 = {player_id_4, status_4, name_4, alliance_name_4, n_villages_4, total_population_4}


    players = [player_1, player_2, player_3, player_4]
    extra_attrs = [extra_attr_1, extra_attr_2, extra_attr_4]


    output = Medusa.CombineAttrs.combine(players, extra_attrs)

    assert(player_output_1 in output)
    assert(player_output_2 in output)
    assert(player_output_4 in output)
    assert(player_output_3 not in output)
  end

end
