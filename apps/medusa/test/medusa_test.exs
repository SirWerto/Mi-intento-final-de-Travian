defmodule MedusaTest do
  use ExUnit.Case
  doctest Medusa

  doctest Medusa.VillageHistoric


   test "Medusa.Producer is alive" do
     prod = Process.whereis(Medusa.Producer)
     assert prod != nil
     assert Supervisor.which_children(Medusa.Supervisor) == [{"producer", prod, :worker, [Medusa.Producer]}]
   end

   test "Medusa eval_players" do
     players_id = ["player1", "player2"]
     assert(:ok == Medusa.eval_players(players_id), "Players are not going throught the pipeline")
   end

   test "Medusa eval_players empty players" do
     players_id = []
     assert(:ok == Medusa.eval_players(players_id), "Players are not going throught the pipeline")
   end



  test "Raise in case of 0 in n_days while quering one player" do
    assert_raise(ArgumentError, fn -> Medusa.Queries.get_historic("player1", 0) end)
  end

  test "Raise in case of negative n_days while quering one player" do
    assert_raise(ArgumentError, fn -> Medusa.Queries.get_historic("player1", -1) end)
    assert_raise(ArgumentError, fn -> Medusa.Queries.get_historic("player1", -2) end)
  end


  test "Raise in case of 0 in n_days while quering multiple player" do
    players = ["player1", "player2"]
    assert_raise(ArgumentError, fn -> Medusa.Queries.get_historics(players, 0) end)
  end

  test "Raise in case of negative n_days while quering multiple player" do
    players = ["player1", "player2"]
    assert_raise(ArgumentError, fn -> Medusa.Queries.get_historics(players, -1) end)
    assert_raise(ArgumentError, fn -> Medusa.Queries.get_historics(players, -2) end)
  end


  test "Raise in case of 0 in n_days while quering all players" do
    assert_raise(ArgumentError, fn -> Medusa.Queries.get_all_historics(0) end)
  end

  test "Raise in case of negative n_days while quering all players" do
    assert_raise(ArgumentError, fn -> Medusa.Queries.get_all_historics(-1) end)
    assert_raise(ArgumentError, fn -> Medusa.Queries.get_all_historics(-2) end)
  end

  test "historic of one player" do
    player_id = "https://ts8.x1.international.travian.com--2021-09-23--P986"
    n_days = DateTime.utc_now() |> DateTime.to_date() |> Date.diff(~D[2021-10-11])

    result = [
      {"https://ts8.x1.international.travian.com--2021-09-23--P986",
       "https://ts8.x1.international.travian.com--2021-09-23--V23671",
       ~D[2021-10-11], 6, 26},
      {"https://ts8.x1.international.travian.com--2021-09-23--P986",
       "https://ts8.x1.international.travian.com--2021-09-23--V17742",
       ~D[2021-10-11], 6, 295}]
    assert Medusa.Queries.get_historic(player_id, n_days) |> TDB.Repo.all() == result
  end

  test "historic of two player" do
    players_id = ["https://ts8.x1.international.travian.com--2021-09-23--P986", "https://ts8.x1.international.travian.com--2021-09-23--P985"]
    n_days = DateTime.utc_now() |> DateTime.to_date() |> Date.diff(~D[2021-10-11])

    result = [
      {"https://ts8.x1.international.travian.com--2021-09-23--P985",
       "https://ts8.x1.international.travian.com--2021-09-23--V17741",
       ~D[2021-10-11], 6, 421},
      {"https://ts8.x1.international.travian.com--2021-09-23--P986",
       "https://ts8.x1.international.travian.com--2021-09-23--V23671",
       ~D[2021-10-11], 6, 26},
      {"https://ts8.x1.international.travian.com--2021-09-23--P985",
       "https://ts8.x1.international.travian.com--2021-09-23--V22977",
       ~D[2021-10-11], 6, 134},
      {"https://ts8.x1.international.travian.com--2021-09-23--P986",
       "https://ts8.x1.international.travian.com--2021-09-23--V17742",
       ~D[2021-10-11], 6, 295}]
    assert Medusa.Queries.get_historics(players_id, n_days) |> TDB.Repo.all() == result
  end


### SetUp
### Private Functions
end
