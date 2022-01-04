defmodule CollectorTest do
  use ExUnit.Case
  doctest Collector




  # #property testing candidate
  # test "process server information to database mappers" do
  #   server = {url, init_date} = {"https://ts4.x1.europe.travian.com", ~U[2019-10-31 19:59:03Z]}
  #   {:ok, aditional_info} = Collector.ScrapServerInfo.get_aditional_info(url)
  #   {:ok, server_map} = Collector.ScrapMap.get_map(url)
  #   {:ok, {server, villages, players, alliances, players_villages_daily, alliances_players}} = Collector.ProcessServer.process(server, aditional_info, server_map)
  #   true == is_map(server)
  #   Enum.map(villages, fn village -> true == is_map(village) end)
  #   Enum.map(players, fn player -> true == is_map(player) end)
  #   Enum.map(alliances, fn alliance -> true == is_map(alliance) end)
  #   Enum.map(players_villages_daily, fn player_village_daily -> true == is_map(player_village_daily) end)
  #   Enum.map(alliances_players, fn alliance_player -> true == is_map(alliance_player) end)
  # end

end
