defmodule PredictionBank do
  require Record

  @moduledoc """
  Documentation for `PredictionBank`.
  """

  Record.defrecord(:bank_players, player_id: "player_id", server_url: "url", player_uid: "puid", state: "active", date: DateTime.now!("Etc/UTC") |> DateTime.to_date())

  @type t :: record(:bank_players, player_id: binary(), server_url: binary(), player_uid: binary(), state: binary(), date: Date.t())


  
  @spec install(nodes :: [atom()]) :: :ok | {:error, any()}
  def install(nodes) do
    :rpc.multicall(nodes, :application, :stop, [:mnesia])
    case :mnesia.create_schema(nodes) do
      {:error, reason} -> {:error, reason}
      :ok -> 
	:rpc.multicall(nodes, :application, :start, [:mnesia])
	
	create_bank_players_table(nodes)
	:ok
    end
  end


  @spec uninstall(nodes :: [atom()]) :: :ok | {:error, any()}
  def uninstall(nodes) do
    :rpc.multicall(nodes, :application, :stop, [:mnesia])
    case :mnesia.delete_schema(nodes) do
      {:error, reason} -> {:error, reason}
      :ok -> 
	:rpc.multicall(nodes, :application, :start, [:mnesia])
	:ok
    end
  end

  @spec create_bank_players_table(nodes :: [atom()]) :: {:atomic, any()} | {:aborted, any()}
  defp create_bank_players_table(nodes) do
    bank_players_options = [
      attributes: [:player_id, :server_url, :player_uid, :state, :date],
      disc_copies: nodes,
      index: [:server_url, :state],
      type: :set
    ]

    :mnesia.create_table(:bank_players, bank_players_options)
  end

  @spec select(server_url :: binary()) :: [[binary()]]
  def select(server_url) do
    match_head = {:bank_players, :"$0", server_url, :_, :"$1", :_}
    guards = []
    results = [:"$$"]

    match_function = {match_head, guards, results}

    f = fn -> :mnesia.select(:bank_players, [match_function]) end
    :mnesia.activity(:transaction, f) |> Enum.sort()
  end

  @spec current_servers() :: [binary()]
  def current_servers() do
    match_head = {:bank_players, :_, :"$0", :_, :_, :_}
    guards = []
    results = [:"$$"]

    match_function = {match_head, guards, results}

    f = fn -> :mnesia.select(:bank_players, [match_function]) end
    :mnesia.activity(:transaction, f) |> Enum.flat_map(fn x -> x end) |> Enum.sort() |> Enum.dedup()
  end

  @spec add_players([{player_id :: binary(), state :: binary()}]) :: {:atomic, any()} | {:aborted, any()}
  def add_players(players) do
    func = fn -> for player <- players, do: :mnesia.write(make_record_from_player(player)) end
    :mnesia.activity(:transaction, func)
  end

  @spec remove_old_players() :: {:atomic, any()} | {:aborted, any()}
  def remove_old_players() do

    today = DateTime.now!("Etc/UTC") |> DateTime.to_date()
    match_head = {:bank_players, :"$0", :_, :_, :_, :"$1"}
    guards = []
    results = [:"$$"]
    match_function = {match_head, guards, results}
    f = fn -> :mnesia.select(:bank_players, [match_function]) end
    players_to_delete = :mnesia.activity(:transaction, f)
    |> Enum.filter(fn [_player_id, date] -> Date.compare(today, date) == :gt end)

    f = fn -> for [player_id, _date] <- players_to_delete, do: :mnesia.delete(:bank_players, player_id, :write) end
    :mnesia.activity(:transaction, f)

  end

  @spec make_record_from_player({binary(), binary()}) :: t()
  defp make_record_from_player({player_id, state}) do
    # "https://ttq.x2.europe.travian.com--2021-06-16--P9903"
    [server_url, _server_init_date, puid] = String.split(player_id, "--", parts: 3, trim: true)
    bank_players(player_id: player_id, server_url: server_url, player_uid: puid, state: state)
  end

end
