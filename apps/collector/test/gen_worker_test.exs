defmodule GenWorkerTest do
  use ExUnit.Case

  @moduletag :capture_log

  setup_all do
    %{server_id: "https://ts5.x1.europe.travian.com"}
  end

  test "stop GenWorker.Snapshot after max_tries", %{server_id: server_id} do
    max_tries = 3
    state = {server_id, max_tries, max_tries}

    assert(
      {:stop, :normal, state} ==
        Collector.GenWorker.Snapshot.handle_info(:timeout, {server_id, max_tries, max_tries})
    )
  end

  test "raise when attempting to Snapshot.etl if no :root_folder is setup", %{
    server_id: server_id
  } do
    max_tries = 3
    Application.delete_env(:collector, :root_folder)

    assert_raise(ArgumentError, fn ->
      Collector.GenWorker.Snapshot.handle_info(:timeout, {server_id, max_tries, max_tries - 1})
    end)
  end

  test "stop GenWorker.Metadata after max_tries", %{server_id: server_id} do
    max_tries = 3
    state = {server_id, max_tries, max_tries}

    assert(
      {:stop, :normal, state} ==
        Collector.GenWorker.Metadata.handle_info(:timeout, {server_id, max_tries, max_tries})
    )
  end

  test "raise when attempting to Metadata.etl if no :root_folder is setup", %{
    server_id: server_id
  } do
    max_tries = 3
    Application.delete_env(:collector, :root_folder)

    assert_raise(ArgumentError, fn ->
      Collector.GenWorker.Metadata.handle_info(:timeout, {server_id, max_tries, max_tries - 1})
    end)
  end

  @tag :tmp_dir
  test "etl from GenWorker.Snapshot creates Collector.SnapshotRow, raw.sql and Collector.PlayersSnapshot files",
       %{
         server_id: server_id,
         tmp_dir: root_folder
       } do
    today = Date.utc_today()
    Application.put_env(:collector, :root_folder, root_folder)
    assert(:ok == Collector.GenWorker.Snapshot.etl(root_folder, server_id))

    {:ok, {^today, encoded_raw_snapshot}} =
      Storage.open(root_folder, server_id, Collector.raw_snapshot_options(), today)

    {:ok, {^today, encoded_snapshot}} =
      Storage.open(root_folder, server_id, Collector.snapshot_options(), today)

    {:ok, {^today, encoded_players_snapshot}} =
      Storage.open(root_folder, server_id, Collector.players_snapshot_options(), today)

    raw_snapshot = Collector.snapshot_from_format(encoded_raw_snapshot)
    assert(is_binary(raw_snapshot))

    snapshot = Collector.snapshot_from_format(encoded_snapshot)
    Enum.each(snapshot, fn row -> assert(is_struct(row, Collector.SnapshotRow)) end)

    players_snapshot = Collector.players_snapshot_from_format(encoded_players_snapshot)
    Enum.each(players_snapshot, fn player -> assert(is_struct(player, Collector.PlayersSnapshot)) end)
  end

  @tag :tmp_dir
  test "etl from GenWorker.Metadata create a file with a map inside", %{
    server_id: server_id,
    tmp_dir: root_folder
  } do
    today = Date.utc_today()
    Application.put_env(:collector, :root_folder, root_folder)
    assert(:ok == Collector.GenWorker.Metadata.etl(root_folder, server_id))

    {:ok, {^today, encoded_metadata}} =
      Storage.open(root_folder, server_id, Collector.metadata_options(), today)

    metadata = Collector.metadata_from_format(encoded_metadata)

    assert(is_map(metadata))
    assert(Map.has_key?(metadata, "server_id"))
    assert(Map.get(metadata, "server_id") == server_id)
  end
end
