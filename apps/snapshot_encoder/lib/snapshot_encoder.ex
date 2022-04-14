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
    file_server_id = remove_http(server_id)
    folder_name = root_folder <> "/" <> file_server_id
    file_name = folder_name <> "/" <> snapshot_filename(date, file_server_id)

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
    file_server_id = remove_http(server_id)
    folder_name = root_folder <> "/" <> file_server_id
    file_name = folder_name <> "/" <> server_info_filename(date, file_server_id)

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
  def snapshot_filename(date, server_id), do: "snapshot--#{@snapshot_version}--#{server_id}--#{Date.to_string(date)}.json"

  @spec server_info_filename(date :: Date.t(), server_id :: TTypes.server_id()) ::
          String.t()
  def server_info_filename(date, server_id), do: "serverinfo--#{@server_info_version}--#{server_id}--#{Date.to_string(date)}.json"

      #-- test and decide names and pretify

  @spec get_last_server_info(root_folder :: String.t(), server_id :: TTypes.server_id()) :: {:ok, %{}} | {:error, any()}
  def get_last_server_info(root_folder, server_id) do
    case get_server_files(root_folder, server_id) do
      {:ok, :no_files} -> {:ok, :no_files}
      {:ok, files} -> {:ok, Enum.filter(files, fn file -> file[:type] == "serverinfo" end) |> Enum.max_by(fn file -> file[:date] end, Date)}

      {:error, reason} -> {:error, reason}
    end
  end


  @spec get_last_snapshot(root_folder :: String.t(), server_id :: TTypes.server_id()) :: {:ok, %{}} | {:error, any()}
  def get_last_snapshot(root_folder, server_id) do
    case get_server_files(root_folder, server_id) do
      {:ok, files} -> {:ok, Enum.filter(files, fn file -> file[:type] == "snapshot" end) |> Enum.max_by(fn file -> file[:date] end, Date)}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec get_server_files(root_folder :: String.t(), server_id :: TTypes.server_id()) :: {:ok, [%{}]} | {:error, any()}
  def get_server_files(root_folder, server_id) do
    case File.ls("#{root_folder}/#{remove_http(server_id)}") do
      {:ok, []} -> {:ok, :no_files}
      {:ok, files} -> {:ok, Enum.map(files, &from_filename!/1)}
      {:error, reason} -> {:error, reason}
    end
  end

  ##@spec from_filename!(filename :: String.t()) :: %{}
  defp from_filename!(filename) do
	[type, version, server_id, dirty_date] = String.split(filename, "--")
	len_date = String.length(dirty_date)-5
	<<string_date::binary-size(len_date), ".json">> = dirty_date
	date = Date.from_iso8601!(string_date)
	%{type: type, version: version, server_id: server_id, date: date, filename: filename}
  end

  @spec remove_http(http_string :: String.t()) :: String.t()
  defp remove_http(<<"https://", server_id::binary>>), do: server_id
  defp remove_http(<<"http://", server_id::binary>>), do: server_id

end
