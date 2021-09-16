defmodule CollectorTest do
  use ExUnit.Case
  doctest Collector


  test "ensure tasksup is launched" do
    assert 1 == Supervisor.which_children(Collector.Supervisor)
    |>Enum.filter(fn {"tasksup", _, :supervisor, [_]} -> true
    _ -> false end)
    |> length()
  end


  test "get current Collector state" do
    case Collector.state? do
      {:ok, :waiting} -> true
      {:ok, :collecting} -> true
      # {:error, :timeout} -> true
      _ -> raise "unexpected answer"
    end
  end

  #property testing candidate
  test "get current subscribers" do
    case Collector.subscribers do
      {:ok, _subscribers} -> true
      # {:error, :timeout} -> true
      _ -> raise "unexpected answer"
    end
  end


  #property testing candidate
  test "subscribe" do
    mypid = self()
    {:ok, :subscribed} = Collector.subscribe(mypid)
    {:ok, [mypid]} = Collector.subscribers()
  end

  #property testing candidate
  test "subscribe with bad pid" do
    case Collector.subscribe(:bad_pid) do
      {:error, :not_valid_pid} -> true
      # {:error, :timeout} -> true
      _ -> raise "unexpected answer"
    end
  end

  #property testing candidate
  test "unsubscribe" do
    {:ok, :subscribed} = Collector.subscribe(self())
    {:ok, :unsubscribed} = Collector.unsubscribe(self())
    {:ok, []} = Collector.subscribers()
  end

  #property testing candidate
  test "unsubscribe without subscribe" do
    {:ok, :unsubscribed} = Collector.unsubscribe(self())
  end

  #property testing candidate
  test "unsubscribe with bad pid" do
    {:ok, :unsubscribed} = Collector.unsubscribe(:bad_pid)
  end

  test "force collecting" do
    {:ok, :waiting} = Collector.state?()
    {:ok, :collecting} = Collector.force_collecting()
    {:ok, :collecting} = Collector.state?()
    Process.exit(Process.whereis(Collector.Plubio), :kill)
    Process.sleep(5000) # this should be change to sleep until Collector Plubio is up
  end

  # test "force collecting change state" do
  #   {:ok, :waiting} = Collector.state?()
  #   {:ok, :collecting} = Collector.force_collecting()
  #   {:ok, :collecting} = Collector.state?()
  # end

  test "get servers status" do
    {:ok, _servers} = Collector.servers_status()
  end

  #property testing candidate
  test "get current collection time" do
    {:ok, _ctime} = Collector.get_ctime()
  end


  #property testing candidate
  test "process server information to database mappers" do
    server = {url, init_date} = {"https://ts4.x1.europe.travian.com", ~U[2019-10-31 19:59:03Z]}
    {:ok, aditional_info} = Collector.ScrapServerInfo.get_aditional_info(url)
    {:ok, server_map} = Collector.ScrapMap.get_map(url)
    {:ok, {server, villages, players, alliances, players_villages_daily, alliances_players}} = Collector.ProcessServer.process(server, aditional_info, server_map)
    true == is_map(server)
    Enum.map(villages, fn village -> true == is_map(village) end)
    Enum.map(players, fn player -> true == is_map(player) end)
    Enum.map(alliances, fn alliance -> true == is_map(alliance) end)
    Enum.map(players_villages_daily, fn player_village_daily -> true == is_map(player_village_daily) end)
    Enum.map(alliances_players, fn alliance_player -> true == is_map(alliance_player) end)
  end

end
