defmodule CollectorTest do
  use ExUnit.Case
  doctest Collector

  @moduletag :capture_log

  setup_all do
    %{server_id: "https://ts5.x1.europe.travian.com"}
  end

  @tag :skip
  test "Collector.subscribe() monitors the Collector.GenCollector process" do
    {:ok, ref} = Collector.subscribe()
    :ok = GenServer.stop(Collector.GenCollector)
    assert_receive({:DOWN, ^ref, :process, _, _})
  end

  # @tag :tmp_dir
  @tag :skip
  test "Being subscribed makes you receive events", %{server_id: server_id, tmp_dir: root_folder} do
    Application.put_env(:collector, :root_folder, root_folder)
    Application.put_env(:collector, :delay_max, 10)
    Application.put_env(:collector, :delay_min, 0)

    {:ok, _ref} = Collector.subscribe()
    Collector.collect()

    assert_receive({:collector_event, {:snapshot_collected, ^server_id}}, 10_000)
    assert_receive({:collector_event, {:snapshot_errors_no_collected, ^server_id}}, 10_000)
    assert_receive({:collector_event, {:metadata_collected, ^server_id}}, 10_000)
  end

  # @tag :tmp_dir
  @tag :skip
  test "Collector.collect() launch the starter event", %{tmp_dir: root_folder} do
    Application.put_env(:collector, :root_folder, root_folder)

    {:ok, _ref} = Collector.subscribe()
    Collector.collect()

    assert_receive({:collector_event, :collection_started}, 10_000)
  end
end
