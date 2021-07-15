defmodule Collector.ScrapServerInfo do
  require Logger


  @login "/login.php"
  @headers [{"User-Agent", "Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:76.0) Gecko/20100101 Firefox/76.0"}]



  @spec get_aditional_info(Collector.url()) :: {:ok, map()} | {:error, any()}
  def get_aditional_info(url) do
    case Finch.build(:get, url <> @login, @headers) |> Finch.request(TFinch) do
      {:ok, response} ->
	case response.status do
	  200 ->
	    try do
	      info = handle_server_html(response.body)
	      Logger.debug("Succsefully parsed aditonal info " <> url)
	      {:ok, info}
	    rescue
	      e in RuntimeError ->
		Logger.critical("Fails while parsing aditional server info " <> url <> " with error " <> e.message)
		{:error, {:parsing_error, e}}
	    end

	  bad_status ->
	    Logger.warn("Bad status response " <> url <> " status-> " <> Integer.to_string(bad_status))
	    {:error, {:bad_status, bad_status}}
	end
      {:error, reason} ->
	Logger.error("Error " <> url <> " reason-> " <> IO.inspect(reason))
	{:error, reason}
    end
  end


  @spec handle_server_html(body :: String.t()) :: map()
  defp handle_server_html(html_body) do
    get_game_options(html_body)
    |> Map.put("version", get_version(html_body))
    |> Map.put("speed", get_speed(html_body))
    |> Map.put("appId", get_app_id(html_body))
    |> Map.put("worldId", get_world_id(html_body))
    |> Map.put("country", get_country(html_body))
    |> Map.merge(get_map_dims(html_body)["Map"]["Size"])
  end

  @spec get_version(html_body :: String.t()) :: String.t()
  defp get_version(html_body) do
    [_, part1] = String.split(html_body, "Travian.Game.version = ")
    [part2 | _] = String.split(part1, ";", parts: 2)
    String.replace(part2, "'", "")
  end

  @spec get_country(html_body :: String.t()) :: String.t()
  defp get_country(html_body) do
    [_, part1] = String.split(html_body, "Travian.Game.country = ")
    [part2 | _] = String.split(part1, ";", parts: 2)
    String.replace(part2, "'", "")
  end

  @spec get_app_id(html_body :: String.t()) :: String.t()
  defp get_app_id(html_body) do
    [_, part1] = String.split(html_body, "Travian.applicationId = ")
    [part2 | _] = String.split(part1, ";", parts: 2)
    String.replace(part2, "'", "")
  end

  @spec get_world_id(html_body :: String.t()) :: String.t()
  defp get_world_id(html_body) do
    [_, part1] = String.split(html_body, "Travian.Game.worldId = ")
    [part2 | _] = String.split(part1, ";", parts: 2)
    String.replace(part2, "'", "")
  end

  @spec get_speed(html_body :: String.t()) :: pos_integer()
  defp get_speed(html_body) do
    [_, part1] = String.split(html_body, "Travian.Game.speed = ")
    [speed | _] = String.split(part1, ";", parts: 2)
    String.to_integer(speed)
  end


  @spec get_game_options(html_body :: String.t()) :: map()
  defp get_game_options(html_body) do
    [_, part1] = String.split(html_body, "var T4_feature_flags = ")
    [json | _] = String.split(part1, ";", trim: true)
    Jason.decode!(json)
  end

  @spec get_map_dims(html_body :: String.t()) :: map()
  defp get_map_dims(html_body) do
    [_, part1] = String.split(html_body, "window.TravianDefaults = Object.assign(\n")
    [json , _] = String.split(part1, ",\n", parts: 2)
    Jason.decode!(json)
  end
end
