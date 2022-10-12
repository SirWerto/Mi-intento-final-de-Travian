defmodule Storage do
  @moduledoc """
  Documentation for `Storage`.
  """

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
end
