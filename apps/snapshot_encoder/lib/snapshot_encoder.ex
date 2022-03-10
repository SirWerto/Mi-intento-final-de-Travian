defmodule SnapshotEncoder do
  @moduledoc """
  Documentation for `SnapshotEncoder`.
  """

  @snapshot_version "1.0.0"
  @server_info_version "1.0.0"

  @type normal_snapshot_row_enriched :: %{
          grid_position: TType.grid_position(),
          x: TType.x(),
          y: TType.y(),
          tribe: TType.tribe(),
          village_id: TType.village_id(),
          village_name: TType.village_name(),
          player_id: TType.player_id(),
          player_name: TType.player_name(),
          alliance_id: TType.alliance_id(),
          alliance_name: TType.alliance_name(),
          population: TType.population()
        }

  @type conquer_snapshot_row_enriched :: %{
          grid_position: TType.grid_position(),
          x: TType.x(),
          y: TType.y(),
          tribe: TType.tribe(),
          village_id: TType.village_id(),
          village_name: TType.village_name(),
          player_id: TType.player_id(),
          player_name: TType.player_name(),
          alliance_id: TType.alliance_id(),
          alliance_name: TType.alliance_name(),
          population: TType.population(),
          region: TType.region(),
          bool1: TType.boolean(),
          bool2: TType.boolean(),
          integer1: TType.integer()
        }

  @type enriched_row :: normal_snapshot_row_enriched() | conquer_snapshot_row_enriched()

  @type enriched_snapshot :: [enriched_row()]
  @type server_info :: any()

  @spec encode_snapshot(
          enriched_snapshot :: enriched_snapshot(),
          root_folder :: Path.t(),
          date :: Date.t(),
          server_id :: TTypes.server_id()
        ) :: {:ok, String.t()} | {:error, any()}
  def encode_snapshot(enriched_snapshot, root_folder, date, server_id) do
    folder_name = root_folder <> "/" <> server_id
    file_name = folder_name <> "/" <> make_snapshot_file_name(date, server_id)

    with {:ok, json_string} <- Jason.encode(enriched_snapshot),
         :ok <- File.mkdir_p(folder_name),
         :ok <- File.write(file_name, json_string) do
      {:ok, file_name}
    end
  end

  @spec decode_snapshot(file_name :: Path.t()) :: {:ok, enriched_snapshot()} | {:error, any()}
  def decode_snapshot(file_name) do
    with true <- File.exists?(file_name),
         false <- File.dir?(file_name),
         {:ok, json_string} <- File.read(file_name) do
      try do
        Jason.decode(json_string, keys: :atoms!)
      rescue
        e in ArgumentError -> {:error, e}
      end
    else
      false -> {:error, "file does not exist"}
      true -> {:error, "file_name is a directory"}
      {:error, reason} -> {:error, reason}
    end
  end

  # @spec encode_server_info(server_info :: server_info(), root_folder :: Path.t(), date :: Date.t(), server_id :: TTypes.server_id()) :: {:ok, String.t()} | {:error, any()}
  # def encode_server_info

  # @spec decode_server_info(file_name :: Path.t()) :: {:ok, server_info()} | {:error, any()}
  # def decode_server_info

  @spec make_snapshot_file_name(date :: Date.t(), server_id :: TTypes.server_id()) :: String.t()
  def make_snapshot_file_name(date, server_id),
    do:
      "snapshot--" <>
        @snapshot_version <> "--" <> server_id <> "--" <> Date.to_string(date) <> ".json"

  @spec make_server_info_file_name(date :: Date.t(), server_id :: TTypes.server_id()) ::
          String.t()
  def make_server_info_file_name(date, server_id),
    do:
      "serverinfo--" <>
        @server_info_version <> "--" <> server_id <> "--" <> Date.to_string(date) <> ".json"
end
