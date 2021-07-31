defmodule Collector.Worker do
  require Logger

  @delay_max 300_000
  @delay_min 5_000

  @spec collect(origin :: pid(), {url :: Collector.url(), init_date :: DateTime.t()}) :: :normal
  def collect(origin, {url, init_date}) do

    sleep = :rand.uniform(@delay_max - @delay_min) + @delay_min
    Logger.debug("Sleeping for " <> Integer.to_string(sleep) <> " " <> url)
    Process.sleep(sleep)
    Logger.debug("Waked up " <> url)
    {:ok, aditional_info} = Collector.ScrapServerInfo.get_aditional_info(url)
    Logger.debug("Scraped server info " <> url)
    {:ok, server_map} = Collector.ScrapMap.get_map(url)
    Logger.debug("Scraped map " <> url)
    :gen_statem.cast(origin, {:collected, self(), url})
    server = process!({url, init_date}, aditional_info, server_map)
    #IO.inspect(server)
    #:normal
    server
  end

  @spec process!({url :: Collector.url(), init_date :: DateTime.t()}, aditional_info :: map(), server_map :: [map()]) :: map()
  defp process!({url, init_date}, aditional_info, server_map) do
    server = process_server!(url, init_date, aditional_info)
  end

  @spec process_server!(url :: Collector.url(), init_date :: DateTime.t(), aditional_info :: map()) :: term()
  defp process_server!(url, init_date, aditional_info) do
    server_id = url <> Date.to_string(DateTime.to_date(init_date))
    %TDB.Server{
      server_id: server_id,
      url: url,
      init_date: DateTime.to_date(init_date)} |> Map.merge(aditional_info)
  end





end
