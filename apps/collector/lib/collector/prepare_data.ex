defmodule Collector.PrepareData do


  @spec process!({url :: Collector.url(), init_date :: DateTime.t()}, aditional_info :: map(), server_map :: [map()]) :: map()
  def process!({url, init_date}, aditional_info, server_map) do
    server_id = url <> "--" <>Date.to_string(DateTime.to_date(init_date))

    server = process_server!(server_id, url, init_date, aditional_info)
    players = process_players!(server_id, server_map)
    alliances = process_alliances!(server_id, server_map)
    villages = process_villages!(server_id, server_map)
    a_p = process_a_p!(server_id, server_map)
    p_v = process_p_v!(server_id, server_map)
    {server, players, alliances, villages, a_p, p_v}
  end

  @spec process_server!(server_id :: String.t(), url :: Collector.url(), init_date :: DateTime.t(), aditional_info :: map()) :: term()
  defp process_server!(server_id, url, init_date, aditional_info) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    %TDB.Server{
      id: server_id,
      url: url,
      inserted_at: now,
      updated_at: now,
      init_date: DateTime.to_date(init_date)} |> Map.merge(aditional_info)
    |> TDB.Server.validate_from_travian_changeset()
  end


  @spec process_players!(server_id :: String.t(), server_map :: [map()]) :: [map()] #[TDB.Player.t()]
  defp process_players!(server_id, server_map) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    server_map
    |> Enum.map(fn row -> {server_id <> "--P" <> Integer.to_string(row["player_id"]), row["player_name"], row["player_id"]} end)
    |> MapSet.new()
    |> Enum.map(fn {player_id, player_name, game_id} -> %TDB.Player{id: player_id,
								   name: player_name,
								   server_id: server_id,
								   game_id: game_id,
								   inserted_at: now,
								   updated_at: now} end)
    |> Enum.map(fn player -> TDB.Player.validate_from_travian_changeset(player) end)
  end

  @spec process_alliances!(server_id :: String.t(), server_map :: [map()]) :: [map()] #[TDB.Alliance.t()]
  defp process_alliances!(server_id, server_map) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    server_map
    |> Enum.map(fn row -> {server_id <> "--A" <> Integer.to_string(row["alliance_id"]), row["alliance_name"], row["alliance_id"]} end)
    |> MapSet.new()
    |> Enum.map(fn {alliance_id, alliance_name, game_id} -> %TDB.Alliance{id: alliance_id,
									 name: alliance_name,
									 server_id: server_id,
									 game_id: game_id,
									 inserted_at: now,
									 updated_at: now} end)
    |> Enum.map(fn alliance -> TDB.Alliance.validate_from_travian_changeset(alliance) end)
  end

  @spec process_villages!(server_id :: String.t(), server_map :: [map()]) :: [map()] #[TDB.Village.t()]
  defp process_villages!(server_id, server_map) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    server_map
    |> Enum.map(fn row -> {server_id <> "--V" <> Integer.to_string(row["village_id"]),
			  row["village_name"],
			  row["x"],
			  row["y"],
			  row["grid"],
			  row["village_id"],
			  } end)
    |> MapSet.new()
    |> Enum.map(fn {village_id, village_name, x, y, grid, game_id} -> %TDB.Village{id: village_id,
									 name: village_name,
									 x: x,
									 y: y,
									 grid: grid,
									 game_id: game_id,
									 server_id: server_id,
									 inserted_at: now,
									 updated_at: now,
									 } end)
    |> Enum.map(fn village -> TDB.Village.validate_from_travian_changeset(village) end)
  end

  @spec process_a_p!(server_id :: String.t(), server_map :: [map()]) :: [map()] #[TDB.Village.t()]
  defp process_a_p!(server_id, server_map) do
    date = DateTime.now!("Etc/UTC") |> DateTime.to_date()

    server_map
    |> Enum.map(fn row -> {server_id <> "--A" <> Integer.to_string(row["alliance_id"]),
			   server_id <> "--P" <> Integer.to_string(row["player_id"])} end)
    |> MapSet.new()
    |> Enum.map(fn {alliance_id, player_id} -> %TDB.Alliance_Player{alliance_id: alliance_id,
								   player_id: player_id,
								   start_date: date} end)
    |> Enum.map(fn a_p -> TDB.Alliance_Player.validate_from_travian_changeset(a_p) end)
  end

  @spec process_p_v!(server_id :: String.t(), server_map :: [map()]) :: [map()] #[TDB.Village.t()]
  defp process_p_v!(server_id, server_map) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    date = DateTime.now!("Etc/UTC") |> DateTime.to_date()

    server_map
    |> Enum.map(fn row -> {server_id <> "--P" <> Integer.to_string(row["player_id"]),
			  server_id <> "--V" <> Integer.to_string(row["village_id"]),
			  row["population"],
			  row["race"]
			  } end)
    |> MapSet.new()
    |> Enum.map(fn {player_id, village_id, population, race} -> %TDB.Player_Village_Daily{player_id: player_id,
											 village_id: village_id,
											 day: date,
											 population: population,
											 race: race,
											 inserted_at: now,
											 updated_at: now
											 } end)
    |> Enum.map(fn p_v -> TDB.Player_Village_Daily.validate_from_travian_changeset(p_v) end)
  end
end
