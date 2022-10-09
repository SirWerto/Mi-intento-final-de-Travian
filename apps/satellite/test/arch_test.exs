defmodule SatelliteArchTest do
  use ExUnit.Case

  setup do
    {:ok, cleaner} = Satellite.MedusaTable.GenCleaner.start_link()
    # on_exit(fn -> GenServer.stop(cleaner) end)
    %{cleaner: cleaner}
  end

  test "MedusaTable.GenCleaner is suscribed to Collector", %{cleaner: c} do
    p_collector = Process.whereis(Collector.GenCollector)
    {pid, ref} = :sys.get_state(c)
    assert(p_collector == pid)
    assert(is_reference(ref))
  end

  @tag :tmp_dir
  test "MedusaTable.GenCleaner cleans outdated MedusaTable rows while Collector emits the starter event", %{tmp_dir: mnesia_dir} do

    install(mnesia_dir)

    target_date = Date.utc_today()
    creation_dt = DateTime.utc_now()
    server_id = "https://czsk.x1.czsk.travian.com"

    yesterday = Date.add(target_date, -1)

    one = %Satellite.MedusaTable{
      alliance_id: "https://czsk.x1.czsk.travian.com--A--18",
      server_id: server_id,
      server_url: server_id,
      alliance_name: "00A",
      alliance_url: "00A",
      inactive_in_current: :undefined,
      inactive_in_future: true,
      inactive_probability: 0.8,
      model: :player_1,
      n_villages: 1,
      player_id: "https://czsk.x1.czsk.travian.com--P--1009",
      player_name: "PalMer",
      player_url: "https://czsk.x1.czsk.travian.com--P--1009",
      target_date: target_date,
      creation_dt: creation_dt,
      total_population: 227
    }
    two = %Satellite.MedusaTable{
      alliance_id: "https://czsk.x1.czsk.travian.com--A--26",
      server_id: server_id,
      server_url: server_id,
      alliance_name: "ZBL",
      alliance_url: "ZBL",
      inactive_in_current: :undefined,
      inactive_in_future: true,
      inactive_probability: 0.3,
      model: :player_1,
      n_villages: 2,
      player_id: "https://czsk.x1.czsk.travian.com--P--815",
      player_name: "Klobuk",
      player_url: "https://czsk.x1.czsk.travian.com--P--815",
      target_date: yesterday,
      creation_dt: creation_dt,
      total_population: 1469
    }
    

    input = [one, two]
    # expected = [one]


    assert([:ok, :ok] == Satellite.MedusaTable.insert_predictions(input))
    Collector.collect()
    Process.sleep(4000)
    # assert(expected == Satellite.MedusaTable.get_predictions_by_server(server_id))
    assert([] == Satellite.MedusaTable.get_predictions_by_server(server_id))
    assert([] == Satellite.MedusaTable.get_predictions_by_server(server_id, yesterday))
  end



  defp install(mnesia_dir) do
    dir = File.mkdir_p!(mnesia_dir <> "/mnesia_dir")
    Application.put_env(:mnesia, :dir, dir)
    assert(:ok == Satellite.install([Node.self()]))
  end
end
