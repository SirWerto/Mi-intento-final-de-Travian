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
    server_map = Collector.ScrapMap.get_map(url)
    Logger.debug("Scraped map " <> url)
    :gen_statem.cast(origin, {:collected, self(), url})
    Logger.debug("Message sent " <> url)
    :normal
  end
end
