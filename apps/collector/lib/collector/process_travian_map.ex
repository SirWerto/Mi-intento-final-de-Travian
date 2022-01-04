defmodule Collector.ProcessTravianMap do

  #@type tuple_to_map(:travianmap_mapline.normal_record() | :travianmap_mapline.territory_record()) :: map()
  def tuple_to_map({grid, x, y, tribe, v_id, v_name, p_id, p_name, a_id, a_name, pop}) do
    %{
      :grid_position => grid,
      :x_position => x,
      :y_position => y,
      :tribe => tribe,
      :village_id => v_id,
      :village_name => v_name,
      :player_id => p_id,
      :player_name => p_name,
      :alliance_id => a_id,
      :alliance_name => a_name,
      :population => pop
    }
  end


  def tuple_to_map({grid, x, y, tribe, v_id, v_name, p_id, p_name, a_id, a_name, pop, _region, _, _, _}) do
    %{
      :grid_position => grid,
      :x_position => x,
      :y_position => y,
      :tribe => tribe,
      :village_id => v_id,
      :village_name => v_name,
      :player_id => p_id,
      :player_name => p_name,
      :alliance_id => a_id,
      :alliance_name => a_name,
      :population => pop
    }
  end

  def create_server_id(url, init_date) do
    url <> "--" <>Date.to_string(DateTime.to_date(init_date))
  end

  def process_server(server_id, url, init_date, aditional_info) do
    date_init_date = DateTime.to_date(init_date)
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    %TDB.Server{id: server_id,
		url: url,
		init_date: date_init_date,
		speed: Map.get(aditional_info, "speed", 1),
		inserted_at: now,
		updated_at: now}
    |> TDB.Server.validate_from_travian_changeset()
  end

  def process_players(server_id, server_maps) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    
    server_maps
    |> Enum.map(fn row -> {server_id <> "--P" <> Integer.to_string(row[:player_id]), row[:player_name], row[:player_id]} end)
    |> MapSet.new()
    |> Enum.map(fn x -> process_player(server_id, now, x) end)
  end

  defp process_player(server_id, now, {player_unique_id, player_name, player_game_id}) do
    %TDB.Player{id: player_unique_id,
		name: player_name,
		server_id: server_id,
		game_id: player_game_id,
		inserted_at: now,
		updated_at: now}
    |> TDB.Player.validate_from_travian_changeset()
    end

  @spec process_alliances(server_id :: String.t(), server_maps :: [map()]) :: [map()] #[TDB.Alliance.t()]
  def process_alliances(server_id, server_maps) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    server_maps
    |> Enum.map(fn row -> {server_id <> "--A" <> Integer.to_string(row[:alliance_id]), row[:alliance_name], row[:alliance_id]} end)
    |> MapSet.new()
    |> Enum.map(fn x -> process_alliance(server_id, now, x) end)
  end


  defp process_alliance(server_id, now, {alliance_unique_id, alliance_name, alliance_game_id}) do
    %TDB.Alliance{id: alliance_unique_id,
		name: alliance_name,
		server_id: server_id,
		game_id: alliance_game_id,
		inserted_at: now,
		updated_at: now}
    |> TDB.Alliance.validate_from_travian_changeset()
    end

  @spec process_villages(server_id :: String.t(), server_maps :: [map()]) :: [map()] #[TDB.Village.t()]
  def process_villages(server_id, server_map) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    server_map
    |> Enum.map(fn row -> process_village(server_id, now, row) end)
  end

  defp process_village(server_id, now, row) do
    village_unique_id = server_id <> "--V" <> Integer.to_string(row[:village_id])

    %TDB.Village{id: village_unique_id,
		  name: row[:village_name],
		  x: row[:x_position],
		  y: row[:y_position],
		  grid: row[:grid_position],
		  server_id: server_id,
		  game_id: row[:village_id],
		  inserted_at: now,
		  updated_at: now}
    |> TDB.Village.validate_from_travian_changeset()
    end

  @spec process_a_ps(server_id :: String.t(), server_maps :: [map()]) :: [map()] #[TDB.Alliance_Player.t()]
  def process_a_ps(server_id, server_maps) do
    date = DateTime.now!("Etc/UTC") |> DateTime.to_date()


    server_maps
    |> Enum.map(fn row -> {server_id <> "--A" <> Integer.to_string(row[:alliance_id]),
			  server_id <> "--P" <> Integer.to_string(row[:player_id])} end)
    |> MapSet.new()
    |> Enum.map(fn {alliance_uid, player_uid} -> process_a_p(date, alliance_uid, player_uid) end)
  end

  defp process_a_p(date, alliance_unique_id, player_unique_id) do
    # alliance_unique_id = server_id <> "--A" <> Integer.to_string(row[:alliance_id])
    # player_unique_id = server_id <> "--P" <> Integer.to_string(row[:player_id])
    
    %TDB.Alliance_Player{alliance_id: alliance_unique_id,
			 player_id: player_unique_id,
			 start_date: date}
    |> TDB.Alliance_Player.validate_from_travian_changeset()
  end


  @spec process_p_vs(server_id :: String.t(), server_maps :: [map()]) :: [map()] #[TDB.Player_Village_Daily.t()]
  def process_p_vs(server_id, server_maps) do
    date = DateTime.now!("Etc/UTC") |> DateTime.to_date()
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    server_maps
    |> Enum.map(fn row -> {server_id <> "--P" <> Integer.to_string(row[:player_id]),
			  server_id <> "--V" <> Integer.to_string(row[:village_id]),
			  row[:population],
			  row[:tribe]} end)
    |> MapSet.new()
    |> Enum.map(fn {player_uid, village_uid, population, tribe} -> process_p_v(date, now, player_uid, village_uid, population, tribe) end)


  end

  defp process_p_v(date, now, player_unique_id, village_unique_id, population, tribe) do
    # player_unique_id = server_id <> "--P" <> Integer.to_string(row[:player_id])
    # village_unique_id = server_id <> "--V" <> Integer.to_string(row[:village_id])
    
    %TDB.Player_Village_Daily{player_id: player_unique_id,
			      village_id: village_unique_id,
			      population: population,
			      race: tribe,
			      day: date,
			      inserted_at: now,
			      updated_at: now}
    |> TDB.Player_Village_Daily.validate_from_travian_changeset()
  end


 end
