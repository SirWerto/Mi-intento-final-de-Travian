defmodule Storage do
  @moduledoc """
  Documentation for `Storage`.
  """

  @snapshot_version "1.0.0"
  @info_version "1.0.0"
  @format ".json.gzip"

  @type open_options :: Date.t() | {Date.t(), Date.t()} | {Date.t(), Date.t(), :consecutive}

  @type dest_identifier :: :global | TTypes.server_id()

  @type flow_name :: binary()
  @type flow_extension :: binary()
  @type flow_options :: {flow_name(), flow_extension()}

  @spec store(
          root_folder :: String.t(),
          identifier :: dest_identifier(),
          flow_options :: flow_options(),
          content :: binary(),
          date :: Date.t()
        ) :: :ok | {:error, any()}
  def store(
        root_folder,
        identifier,
        {flow_name, flow_extension},
        content,
        date \\ Date.utc_today()
      ) do
    dir_path = gen_dir_path(root_folder, identifier, flow_name)
    filename = gen_filename(dir_path, date, flow_extension)

    case File.mkdir_p(dir_path) do
      {:error, reason} ->
        {:error, {"unable to create dir path", reason}}

      :ok ->
        case File.write(filename, content, [:binary]) do
          {:error, reason} -> {:error, {"unable to write the content", reason}}
          :ok -> :ok
        end
    end
  end

  @spec open(
          root_folder :: String.t(),
          identifier :: dest_identifier(),
          flow_options :: flow_options(),
          open_options
        ) :: {:ok, {Date.t(), binary()}} | {:ok, [{Date.t(), binary()}]} | {:error, any()}
  def open(root_folder, identifier, flow_options, {start_date, end_date}) do
    case Date.compare(start_date, end_date) do
      :gt ->
        {:error, "end_date earlier than start_date"}

      :eq ->
        {:error, "end_date and start_date can't be the same"}

      :lt ->
        result =
          gen_date_range!(start_date, end_date)
          |> Enum.map(&open(root_folder, identifier, flow_options, &1))
          |> Enum.filter(fn {atom, _} -> atom == :ok end)
          |> Enum.map(fn {_, content} -> content end)

        {:ok, result}
    end
  end

  def open(root_folder, identifier, flow_options, {start_date, end_date, :consecutive}) do
    case Date.compare(start_date, end_date) do
      :gt ->
        {:error, "end_date earlier than start_date"}

      :eq ->
        open(root_folder, identifier, flow_options, start_date)

      :lt ->
        result =
          gen_date_range!(start_date, end_date)
          |> open_rec([], root_folder, identifier, flow_options)

        {:ok, result}
    end
  end

  def open(root_folder, identifier, {flow_name, flow_extension}, date) do
    dir_path = gen_dir_path(root_folder, identifier, flow_name)
    filename = gen_filename(dir_path, date, flow_extension)

    case File.read(filename) do
      {:ok, content} -> {:ok, {date, content}}
      {:error, reason} -> {:error, {"unable to open the file", reason}}
    end
  end

  defp open_rec([], contents, _root_folder, _identifier, _flow_options), do: contents

  defp open_rec([date | dates], contents, root_folder, identifier, flow_options) do
    case open(root_folder, identifier, flow_options, date) do
      {:error, _reason} ->
        contents

      {:ok, content} ->
        open_rec(dates, contents ++ [content], root_folder, identifier, flow_options)
    end
  end

  @spec gen_dir_path(
          root_folder :: binary(),
          identifier :: dest_identifier(),
          flow_name :: flow_name()
        ) :: binary()
  defp gen_dir_path(root_folder, :global, flow_name), do: "#{root_folder}/global/#{flow_name}"

  defp gen_dir_path(root_folder, server_id, flow_name),
    do: "#{root_folder}/servers/#{TTypes.server_id_to_path(server_id)}/#{flow_name}"

  @spec gen_filename(dir_path :: binary(), date :: Date.t(), flow_extension :: flow_extension()) ::
          binary()
  defp gen_filename(dir_path, date, flow_extension),
    do: "#{dir_path}/date_#{Date.to_iso8601(date, :basic)}#{flow_extension}"

  @spec gen_date_range!(start_date :: Date.t(), end_date :: Date.t()) :: [Date.t()]
  def gen_date_range!(start_date, end_date) do
    diff = Date.diff(end_date, start_date)
    for i <- diff..0, do: Date.add(start_date, i)
  end

  @spec store_snapshot(
          root_folder :: String.t(),
          server_id :: TTypes.server_id(),
          date :: Date.t(),
          snapshot :: [TTypes.enriched_row()]
        ) :: :ok | {:error, any()}
  def store_snapshot(root_folder, server_id, date, snapshot) do
    server_name = mod_name(server_id)

    filename =
      "#{root_folder}/#{server_name}/snapshot/#{create_snapshot_filename(server_name, date)}"

    with :ok <- File.mkdir_p("#{root_folder}/#{server_name}/snapshot"),
         {:ok, formated} <- snapshot_to_format(snapshot, @snapshot_version) do
      File.write(filename, formated)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec store_info(
          root_folder :: String.t(),
          server_id :: TTypes.server_id(),
          date :: Date.t(),
          info :: TTypes.server_info()
        ) :: :ok | {:error, any()}
  def store_info(root_folder, server_id, date, info) do
    server_name = mod_name(server_id)
    filename = "#{root_folder}/#{server_name}/info/#{create_info_filename(server_name, date)}"

    with :ok <- File.mkdir_p("#{root_folder}/#{server_name}/info/"),
         {:ok, formated} <- info_to_format(info, @info_version) do
      File.write(filename, formated)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec fetch_last_info(root_folder :: String.t(), server_id :: TTypes.server_id()) ::
          {:ok, :no_files | TTypes.server_info()} | {:error, any()}
  def fetch_last_info(root_folder, server_id) do
    server_name = mod_name(server_id)
    folder = "#{root_folder}/#{server_name}/info/"
    :ok = File.mkdir_p(folder)

    case File.ls(folder) do
      {:error, reason} ->
        {:error, reason}

      {:ok, []} ->
        {:ok, :no_files}

      {:ok, files} ->
        files =
          files
          |> Enum.filter(fn
            <<"info", _::binary()>> -> true
            _ -> false
          end)

        case files do
          [] ->
            {:ok, :no_files}

          [last] ->
            process_last_info(last, folder)

          _ ->
            files
            |> Enum.reduce(&get_last_info/2)
            |> process_last_info(folder)
        end
    end
  end

  defp process_last_info(filename, folder) do
    (folder <> filename)
    |> File.read()
    |> info_from_format()
  end

  @spec fetch_last_n_snapshots(
          root_folder :: String.t(),
          server_id :: TTypes.server_id(),
          n :: pos_integer()
        ) :: {:ok, [{Date.t(), [TTypes.enriched_row()]}]} | {:error, any()}
  def fetch_last_n_snapshots(root_folder, server_id, n) do
    server_name = mod_name(server_id)
    folder = "#{root_folder}/#{server_name}/snapshot/"
    :ok = File.mkdir_p("#{root_folder}/#{server_name}/snapshot/")

    case File.ls(folder) do
      {:error, reason} ->
        {:error, reason}

      {:ok, []} ->
        {:ok, []}

      {:ok, files} ->
        tuples =
          files
          |> Enum.filter(fn
            <<"snapshot", _::binary()>> -> true
            _ -> false
          end)
          |> Enum.sort_by(&get_date/1, {:desc, Date})
          |> Enum.take(n)
          |> Enum.map(fn x -> get_snapshot(x, folder) end)
          |> Enum.filter(fn
            {:error, _reason} -> false
            _ -> true
          end)

        {:ok, tuples}
    end
  end

  @spec get_snapshot(filename :: String.t(), folder :: String.t()) ::
          {Date.t(), [TTypes.enriched_row()]} | {:error, any()}
  defp get_snapshot(filename, folder) do
    date = get_date(filename)
    full_filename = folder <> filename

    case File.read(full_filename) do
      {:error, reason} ->
        {:error, reason}

      {:ok, encoded_snapshot} ->
        case snapshot_from_format(encoded_snapshot) do
          {:ok, snapshot} -> {date, snapshot}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  @spec mod_name(server_id :: TTypes.server_id()) :: String.t()
  defp mod_name(server_id), do: String.replace(server_id, "://", "@@")

  @spec create_snapshot_filename(server_name :: String.t(), date :: Date.t()) :: String.t()
  defp create_snapshot_filename(server_name, date),
    do: "snapshot--#{@snapshot_version}--#{server_name}--#{Date.to_iso8601(date)}#{@format}"

  @spec create_info_filename(server_name :: String.t(), date :: Date.t()) :: String.t()
  defp create_info_filename(server_name, date),
    do: "info--#{@info_version}--#{server_name}--#{Date.to_iso8601(date)}#{@format}"

  @spec snapshot_to_format(snapshot :: [TTypes.enriched_row()], version :: String.t()) ::
          {:ok, binary()} | {:error, any()}
  defp snapshot_to_format(snapshot, _version) do
    case Jason.encode(snapshot) do
      {:error, reason} -> {:error, reason}
      {:ok, json} -> {:ok, :zlib.gzip(json)}
    end
  end

  @spec snapshot_from_format(encoded_info :: binary()) ::
          {:ok, [TTypes.enriched_row()]} | {:error, any()}
  defp snapshot_from_format(snapshot) do
    snapshot
    |> :zlib.gunzip()
    |> Jason.decode(keys: :atoms!)
  end

  @spec info_to_format(info :: TTypes.server_info(), version :: String.t()) ::
          {:ok, binary()} | {:error, any()}
  defp info_to_format(info, _version) do
    case Jason.encode(info) do
      {:error, reason} -> {:error, reason}
      {:ok, json} -> {:ok, :zlib.gzip(json)}
    end
  end

  @spec info_from_format({:ok, encoded_info :: binary()} | {:error, any()}) ::
          {:ok, TTypes.server_info()} | {:error, any()}
  defp info_from_format({:ok, encoded_info}) do
    encoded_info
    |> :zlib.gunzip()
    |> Jason.decode()
  end

  defp info_from_format({:error, reason}), do: {:error, reason}

  @spec get_last_info(filename_1 :: String.t(), filename_2 :: String.t()) :: String.t()
  defp get_last_info(filename_1, filename_2) do
    date1 = get_date(filename_1)
    date2 = get_date(filename_2)

    case Date.compare(date1, date2) do
      :gt -> filename_1
      :lt -> filename_2
    end
  end

  defp get_date(filename) do
    [_, _, _, dirty] = String.split(filename, "--")
    String.replace(dirty, @format, "") |> Date.from_iso8601!()
  end
end
