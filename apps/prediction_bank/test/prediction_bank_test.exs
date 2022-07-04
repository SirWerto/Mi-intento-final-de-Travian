defmodule PredictionBankTest do
  use ExUnit.Case
  doctest PredictionBank

  setup do
    mnesia_dir_test = Application.fetch_env!(:prediction_bank, :mnesia_dir_test)
    Application.put_env(:mnesia, :dir, mnesia_dir_test)
    PredictionBank.install([node()])

    on_exit(fn -> PredictionBank.uninstall([node()]) end)
  end

  test "view current servers" do
    player_id1 = "https://ttq.x2.europe.travian.com--2021-06-16--P9903"
    player_id2 = "https://ttq.x2.africa.travian.com--2021-06-16--P9903"
    state1 = "future_inactive"
    state2 = "active"
    url1 = "https://ttq.x2.europe.travian.com"
    url2 = "https://ttq.x2.africa.travian.com"

    player_name1 = "name1"
    player_name2 = "name2"

    alliance_name1 = "a_name1"
    alliance_name2 = "a_name2"

    n_villages1 = 2
    n_villages2 = 10

    total_population1 = 100
    total_population2 = 800

    player1 = {player_id1, state1, player_name1, alliance_name1, n_villages1, total_population1}
    player2 = {player_id2, state2, player_name2, alliance_name2, n_villages2, total_population2}

    assert([:ok, :ok] == PredictionBank.add_players([player1, player2]))
    assert(Enum.sort([url1, url2]) == PredictionBank.current_servers())
  end

  test "select one player by server" do
    player_id1 = "https://ttq.x2.europe.travian.com--2021-06-16--P9903"
    player_id2 = "https://ttq.x2.africa.travian.com--2021-06-16--P9903"
    state1 = "future_inactive"
    state2 = "active"
    _url1 = "https://ttq.x2.europe.travian.com"
    url2 = "https://ttq.x2.africa.travian.com"

    player_name1 = "name1"
    player_name2 = "name2"

    alliance_name1 = "a_name1"
    alliance_name2 = "a_name2"

    n_villages1 = 2
    n_villages2 = 10

    total_population1 = 100
    total_population2 = 800

    player1 = {player_id1, state1, player_name1, alliance_name1, n_villages1, total_population1}
    player2 = {player_id2, state2, player_name2, alliance_name2, n_villages2, total_population2}

    assert([:ok, :ok] == PredictionBank.add_players([player1, player2]))

    select_p2 = {player_id2, player_name2, alliance_name2, n_villages2, total_population2, state2}

    assert([select_p2] == PredictionBank.select(url2))
  end

  test "select multple players by server" do
    player_id1 = "https://ttq.x2.europe.travian.com--2021-06-16--P9903"
    player_id2 = "https://ttq.x2.africa.travian.com--2021-06-16--P9903"
    player_id3 = "https://ttq.x2.africa.travian.com--2021-06-16--P9904"
    state1 = "future_inactive"
    state2 = "active"
    state3 = "inactive"
    _url1 = "https://ttq.x2.europe.travian.com"
    url2 = "https://ttq.x2.africa.travian.com"
    _url3 = "https://ttq.x2.africa.travian.com"

    player_name1 = "name1"
    player_name2 = "name2"
    player_name3 = "name3"

    alliance_name1 = "a_name1"
    alliance_name2 = "a_name2"
    alliance_name3 = "a_name3"

    n_villages1 = 2
    n_villages2 = 10
    n_villages3 = 5

    total_population1 = 100
    total_population2 = 800
    total_population3 = 400

    player1 = {player_id1, state1, player_name1, alliance_name1, n_villages1, total_population1}
    player2 = {player_id2, state2, player_name2, alliance_name2, n_villages2, total_population2}
    player3 = {player_id3, state3, player_name3, alliance_name3, n_villages3, total_population3}

    assert([:ok, :ok, :ok] == PredictionBank.add_players([player1, player2, player3]))

    select_p2 = {player_id2, player_name2, alliance_name2, n_villages2, total_population2, state2}
    select_p3 = {player_id3, player_name3, alliance_name3, n_villages3, total_population3, state3}

    assert(Enum.sort([select_p2, select_p3]) == PredictionBank.select(url2))
  end

  test "remove registers which are not updated today" do
    date_yesterday = DateTime.now!("Etc/UTC") |> DateTime.to_date() |> Date.add(-1)

    player_id1 = "https://ttq.x2.africa.travian.com--2021-06-16--P9903"
    player_id2 = "https://ttq.x2.africa.travian.com--2021-06-16--P9904"
    state1 = "future_inactive"
    state2 = "active"
    url2 = "https://ttq.x2.africa.travian.com"

    player_name1 = "name1"
    player_name2 = "name2"

    alliance_name1 = "a_name1"
    alliance_name2 = "a_name2"

    n_villages1 = 2
    n_villages2 = 10

    total_population1 = 100
    total_population2 = 800

    player1 = {player_id1, state1, player_name1, alliance_name1, n_villages1, total_population1}
    _player2 = {player_id2, state2, player_name2, alliance_name2, n_villages2, total_population2}

    func = fn ->
      :mnesia.write(
        PredictionBank.bank_players(
          player_id: player_id2,
          server_url: url2,
          player_name: player_name2,
          alliance_name: alliance_name2,
          n_villages: n_villages2,
          total_population: total_population2,
          state: state2,
          date: date_yesterday
        )
      )
    end

    :mnesia.activity(:transaction, func)

    assert([:ok] == PredictionBank.add_players([player1]))

    select_p1 = {player_id1, player_name1, alliance_name1, n_villages1, total_population1, state1}
    select_p2 = {player_id2, player_name2, alliance_name2, n_villages2, total_population2, state2}

    assert(Enum.sort([select_p1, select_p2]) == PredictionBank.select(url2))
    PredictionBank.remove_old_players()
    assert(Enum.sort([select_p1]) == PredictionBank.select(url2))
  end
end
