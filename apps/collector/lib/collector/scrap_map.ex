defmodule Collector.ScrapMap do
  require Logger



  @map "/map.sql"
  @headers [{"User-Agent", "Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:76.0) Gecko/20100101 Firefox/76.0"}]



  def get_map(url) do
    case Finch.build(:get, url <> @map, @headers) |> Finch.request(TFinch) do
      {:ok, response} ->
	case response.status do
	  200 ->
	    handle_map_sql(response.body)
	  bad_status ->
	    Logger.warn("Bad status response " <> url <> " status-> " <> Integer.to_string(bad_status))
	    {:error, {:bad_status, bad_status}}
	end
      {:error, reason} ->
	Logger.error("Error " <> url <> " reason-> " <> IO.inspect(reason))
	{:error, reason}
    end
  end


  @spec handle_map_sql(map_sql :: String.t()) :: [map()]
  defp handle_map_sql(map_sql) do
    map_sql
    |> String.split("\n", trim: true)
    |> Enum.map(&remove_sql/1)
    |> Enum.filter(fn :error -> false
      _ -> true end)
    |> Enum.filter(&enough_commas?/1)
    |> Enum.map(&try_map_factory/1)
    |> Enum.filter(fn :error -> false
      _ -> true end)
  end

  @spec remove_sql(sql_stament :: String.t()) :: String.t()
  defp remove_sql(sql_stament) do
    data_s = byte_size(sql_stament) - 30 - 2
    try do
    <<"INSERT INTO `x_world` VALUES (", csv_data::binary-size(data_s), ");">> = sql_stament
    csv_data
    rescue
      e in RuntimeError ->
	Logger.critical("Fails while parsing sql_stament " <> sql_stament <> " with error " <> e.message)
	:error
    end
  end

  @spec enough_commas?(csv_data :: String.t()) :: boolean()
  defp enough_commas?(csv_data) do
    case String.graphemes(csv_data) |> Enum.frequencies() |> (&(&1[","])).() do
      n when n >= 11 -> 
	true
      n -> 
	Logger.debug(Integer.to_string(n) <> " bad commas " <> csv_data)
	false
    end
  end


  @spec try_map_factory(csv_data :: String.t()) :: map() | :error
  defp try_map_factory(csv_data) do
    try do
      map_factory(csv_data)
    rescue
      e in RuntimeError ->
	Logger.debug("Fails while parsing csv_data " <> csv_data <> " with error " <> e.message)
	:error
    end
  end

  @spec map_factory(csv_data :: String.t()) :: map()
  defp map_factory(csv_data) do
    mymap = %{}
    [grid, part1] = String.split(csv_data, ",", parts: 2)
    mymap = Map.put(mymap, "grid", String.to_integer(grid))
    [x, part2] = String.split(part1, ",", parts: 2)
    mymap = Map.put(mymap, "x", String.to_integer(x))
    [y, part3] = String.split(part2, ",", parts: 2)
    mymap = Map.put(mymap, "y", String.to_integer(y))
    [race, part4] = String.split(part3, ",", parts: 2)
    mymap = Map.put(mymap, "race", String.to_integer(race))
    [village_id, part5] = String.split(part4, ",", parts: 2)
    mymap = Map.put(mymap, "village_id", String.to_integer(village_id))
    [_, village_name, part6] = String.split(part5, "'", parts: 3)
    mymap = Map.put(mymap, "village_name", village_name)
    [player_id, part7] = String.split(part6, ",", [parts: 2, trim: true])
    mymap = Map.put(mymap, "player_id", String.to_integer(player_id))
    [_, player_name, part8] = String.split(part7, "'", parts: 3)
    mymap = Map.put(mymap, "player_name", player_name)
    [alliance_id, part9] = String.split(part8, ",", [parts: 2, trim: true])
    mymap = Map.put(mymap, "alliance_id", String.to_integer(alliance_id))
    [_, alliance_name, part10] = String.split(part9, "'", parts: 3)
    mymap = Map.put(mymap, "alliance_name", alliance_name)
    [population, territory] = String.split(part10, ",", [parts: 2, trim: true])
    mymap = Map.put(mymap, "population", String.to_integer(population))
    mymap = Map.put(mymap, "territory", territory)
    mymap
  end


end
