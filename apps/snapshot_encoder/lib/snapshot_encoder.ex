defmodule SnapshotEncoder do
  @moduledoc """
  Documentation for `SnapshotEncoder`.
  """

  @snapshot_version "1.0.0"
  @server_info_version "1.0.0"

  @type enriched_snapshot :: [TTypes.enriched_row()]
  @type server_info :: %{String.t() => any()}

  @spec encode(
          enriched_snapshot :: enriched_snapshot(),
          root_folder :: Path.t(),
          date :: Date.t(),
          server_id :: TTypes.server_id()
        ) :: {:ok, String.t()} | {:error, any()}
  def encode(enriched_snapshot, root_folder, date, server_id) do
    folder_name = root_folder <> "/" <> server_id
    file_name = folder_name <> "/" <> snapshot_filename(date, server_id)

    with {:ok, json_string} <- Jason.encode(enriched_snapshot),
         :ok <- File.mkdir_p(folder_name),
         :ok <- File.write(file_name, json_string) do
      {:ok, file_name}
    end
  end

  @spec decode(file_name :: Path.t()) :: {:ok, enriched_snapshot()} | {:error, any()}
  def decode(file_name) do
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

  @spec encode_info(server_info :: server_info(), root_folder :: Path.t(), date :: Date.t(), server_id :: TTypes.server_id()) :: {:ok, String.t()} | {:error, any()}
  def encode_info(server_info, root_folder, date, server_id) do
    folder_name = root_folder <> "/" <> server_id
    file_name = folder_name <> "/" <> server_info_filename(date, server_id)

    with true <- Enum.all?(Map.keys(server_info), fn key -> is_binary(key) end),
    {:ok, json_string} <- Jason.encode(server_info),
         :ok <- File.mkdir_p(folder_name),
         :ok <- File.write(file_name, json_string) do
      {:ok, file_name}
    else
      false -> {:error, "keys must be String.t()"}
    {:error, reason} -> {:error, reason}
    end
  end

  @spec decode_info(file_name :: Path.t()) :: {:ok, server_info()} | {:error, any()}
  def decode_info(file_name) do
    with true <- File.exists?(file_name),
         false <- File.dir?(file_name),
         {:ok, json_string} <- File.read(file_name) do
        Jason.decode(json_string)
    else
      false -> {:error, "file does not exist"}
      true -> {:error, "file_name is a directory"}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec snapshot_filename(date :: Date.t(), server_id :: TTypes.server_id()) :: String.t()
  def snapshot_filename(date, server_id),
    do:
      "snapshot--" <>
        @snapshot_version <> "--" <> server_id <> "--" <> Date.to_string(date) <> ".json"

  @spec server_info_filename(date :: Date.t(), server_id :: TTypes.server_id()) ::
          String.t()
  def server_info_filename(date, server_id),
    do:
      "serverinfo--" <>
        @server_info_version <> "--" <> server_id <> "--" <> Date.to_string(date) <> ".json"
end
