defmodule SnapshotEncoderTest do
  use ExUnit.Case
  doctest SnapshotEncoder

  setup do
    root_folder = "/tmp/SnapshotEncoderTest"
    :ok = File.mkdir_p(root_folder)
    on_exit(fn -> File.rmdir(root_folder) end)
    %{root_folder: root_folder}
  end

  test "encode and decode snapshot", %{:root_folder => root_folder} do
    enriched_snapshot = [
      %{
        grid_position: 1,
        x: 1,
        y: 2,
        tribe: 1,
        village_id: "village_id",
        village_name: "village_name",
        player_id: "player_id",
        player_name: "player_name",
        alliance_id: "alliance_id",
        alliance_name: "alliance_name",
        population: 39
      },
      %{
        grid_position: 2,
        x: 2,
        y: 2,
        tribe: 1,
        village_id: "village_id2",
        village_name: "village_name",
        player_id: "player_id2",
        player_name: "player_name",
        alliance_id: "alliance_id2",
        alliance_name: "alliance_name",
        population: 20
      }
    ]

    server_id = "www.some_server.fr"
    date = ~D[2000-02-02]

    {:ok, file_name} =
      SnapshotEncoder.encode_snapshot(enriched_snapshot, root_folder, date, server_id)

    {:ok, snapshot_decoded} = SnapshotEncoder.decode_snapshot(file_name)
    assert enriched_snapshot == snapshot_decoded
  end

  test "decode_snapshot error while decoding no file_name" do
    assert {:error, "file does not exist"} == SnapshotEncoder.decode_snapshot("bad_file_name")
  end

  test "decode_snapshot error while decoding a directory", %{:root_folder => root_folder} do
    assert {:error, "file_name is a directory"} == SnapshotEncoder.decode_snapshot(root_folder)
  end

  test "decode_snapshot fail if there is a no recoginized key", %{:root_folder => root_folder} do
    enriched_snapshot = [%{"no atom key" => "some value"}]
    server_id = "www.some_server.fr"
    date = ~D[2000-02-02]

    {:ok, file_name} =
      SnapshotEncoder.encode_snapshot(enriched_snapshot, root_folder, date, server_id)

    case SnapshotEncoder.decode_snapshot(file_name) do
      {:error, _} -> assert true
      {:ok, _} -> assert false
    end
  end
end
