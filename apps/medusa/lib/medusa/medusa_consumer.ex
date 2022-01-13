defmodule Medusa.Consumer do
  use GenStage
  import Ecto.Query, only: [from: 2]

  @moduledoc """
  Documentation for `MedusaConsumer`.
  """
  @seconds_in_day 3600*24


  defstruct [:port, :port_ref, :model_dir, loaded?: false]

  @type t :: %__MODULE__{
    loaded?: boolean(),
    port: port() | nil,
    port_ref: reference() | nil,
    model_dir: binary() | nil}
  

  @spec start_link(medusa_app_dir :: binary()) :: GenServer.on_start()
  def start_link(medusa_app_dir) do
    GenStage.start_link(__MODULE__, [medusa_app_dir])
  end


  @spec stop(pid :: pid(), reason :: any(), timeout :: pos_integer()) :: :ok
  def stop(pid, reason \\ :normal, timeout \\ 5000) do
    GenStage.stop(pid, reason, timeout)
  end

  @spec send_players(consumer :: pid(), any()) :: :ok
  def send_players(consumer, players), do: GenStage.cast(consumer, {:send_players, players})


  @impl true
  def init([medusa_app_dir]) do
    send(self(), :load_model)
    {:consumer, %__MODULE__{loaded?: false, model_dir: medusa_app_dir}, subscribe_to: [Medusa.Producer]}
  end

  @impl true
  def handle_events(players_ids, _from, state) do
    players_ids
    |> get_last_5_days()
    |> TDB.Repo.all()
    |> MedusaPipeline.apply()
    |> MedusaModels.apply_5d()
    |> MedusaPort.send_players(state.port)
    {:noreply, [], state}
  end

  @impl true
  def handle_info(:load_model, state) do
    {port, ref} = MedusaPort.open_port(state.model_dir)
    true = MedusaPort.load_model(port)

    state = Map.put(state, :port, port)
    |> Map.put(:port_ref, ref)

    {:noreply, [], state}
  end

  def handle_info({port, {:data, "\"loaded\""}}, state = %__MODULE__{port: port}), do: {:noreply, [], state}
  def handle_info({port, {:data, "\"not loaded\""}}, %__MODULE__{port: port}), do: {:noreply, [], :stop}

  def handle_info({port, {:data, predictions = <<"[\"predicted\"", _rest::binary>>}}, state = %__MODULE__{port: port}) do
    ["predicted", predictions] = Jason.decode!(predictions)
    players = for player <- predictions, do: player
    players_id = for {player, _status}<- players, do: player
    pop_attrs = get_population_attributes(players_id) |> TDB.Repo.all()

    Enum.zip(players, pop_attrs)
    |> Enum.map(&zip_player_info/1)
    |> Enum.filter(fn x -> x != {} end)
    |> PredictionBank.add_players()

    {:noreply, [], state}
  end

  def handle_info(_msg, state) do
    {:noreply, [], state}
  end

  defp zip_player_info({{player_id, state}, {player_id, name, a_name, n_villages, total_pop}}) do
    {player_id, state, name, a_name, n_villages, total_pop}
  end
  defp zip_player_info(_), do: {}

  @spec get_last_5_days(players_id :: [binary()]) :: Ecto.Query.t()
  def get_last_5_days(players_id) do
    max_date = DateTime.utc_now() |> DateTime.add(-1*@seconds_in_day*4) |> DateTime.to_date()
    from p_v_d in TDB.Player_Village_Daily,
      where: p_v_d.day >= ^max_date and p_v_d.player_id in ^players_id,
      select: {p_v_d.player_id, p_v_d.village_id, p_v_d.day, p_v_d.race, p_v_d.population}
  end


  @spec get_population_attributes(players_id :: [binary()]) :: Ecto.Query.t()
  def get_population_attributes(players_id) do
    today = DateTime.utc_now() |> DateTime.to_date()
    from players in TDB.Player,
      join: p_v_d in TDB.Player_Village_Daily,
      on: players.id == p_v_d.player_id,
      join: a_p in TDB.Alliance_Player,
      on: players.id == a_p.player_id,
      join: alliances in TDB.Alliance,
      on: a_p.alliance_id == alliances.id,
      where: p_v_d.day == ^today and players.id in ^players_id and a_p.start_date == ^today,
      group_by: [players.id, players.name, alliances.name],
      select: {players.id, players.name, alliances.name, count(p_v_d.village_id), sum(p_v_d.population)}
  end



end
