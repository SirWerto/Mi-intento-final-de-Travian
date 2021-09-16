defmodule Collector.Worker do
  require Logger

  @delay_max 600_000
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
    {server, players, alliances, villages, a_p, p_v} = Collector.PrepareData.process!({url, init_date}, aditional_info, server_map)
    Collector.Queries.insert_or_update_server!(server)
    Collector.Queries.insert_or_update_alliances!(alliances) |> TDB.Repo.transaction()
    Collector.Queries.insert_or_update_players!(players) |> TDB.Repo.transaction()
    Collector.Queries.insert_or_update_villages!(villages) |> TDB.Repo.transaction()
    Collector.Queries.insert_or_update_a_p!(a_p) |> TDB.Repo.transaction()
    Collector.Queries.insert_or_update_p_v!(p_v) |> TDB.Repo.transaction()
    Logger.debug("Stored in db: " <> url)
    :gen_statem.cast(origin, {:collected, self(), url})
    :normal
  end






end
