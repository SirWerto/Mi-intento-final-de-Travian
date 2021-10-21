defmodule Medusa.Queries do
  import Ecto.Query, only: [from: 2]

  @moduledoc """
  Medusa queries's module.
  """

  @seconds_in_day 3600*24
          
  @doc """
  `Medusa.Queries.get_historic` returns the last `n_days` of player's activity
  """
  @spec get_historic(player_id :: Medusa.Types.player_id(), n_days :: pos_integer()) :: Ecto.Query.t()
  def get_historic(player_id, n_days)

  def get_historic(player_id, n_days) when n_days > 0 do
    max_date = DateTime.utc_now() |> DateTime.add(-1*@seconds_in_day*n_days) |> DateTime.to_date()
    from p_v_d in TDB.Player_Village_Daily,
      where: p_v_d.day >= ^max_date and p_v_d.player_id == ^player_id,
      select: {p_v_d.player_id, p_v_d.village_id, p_v_d.day, p_v_d.race, p_v_d.population}
  end

  def get_historic(_, bad_n_days) do
    raise ArgumentError, message: "n_days must be >= 1 and is " <> Integer.to_string(bad_n_days)
  end

  @doc """
  `Medusa.Queries.get_historics` returns the last `n_days` of players's activitys
  """
  @spec get_historics(players_id :: [Medusa.Types.player_id()], n_days :: pos_integer()) :: Ecto.Query.t()
  def get_historics(players_id, n_days)
  def get_historics(players_id, n_days) when n_days > 0 do
    max_date = DateTime.utc_now() |> DateTime.add(-1*@seconds_in_day*n_days) |> DateTime.to_date()
    from p_v_d in TDB.Player_Village_Daily,
      where: p_v_d.day >= ^max_date and p_v_d.player_id in ^players_id,
      select: {p_v_d.player_id, p_v_d.village_id, p_v_d.day, p_v_d.race, p_v_d.population}
  end

  def get_historics(_, bad_n_days) do
    raise ArgumentError, message: "n_days must be >= 1 and is " <> Integer.to_string(bad_n_days)
  end

  @doc """
  `Medusa.Queries.get_historics` returns the activity within last `n_days`
  """
  @spec get_all_historics(n_days :: pos_integer()) :: Ecto.Query.t()
  def get_all_historics(n_days)
  def get_all_historics(n_days) when n_days > 0 do
    max_date = DateTime.utc_now() |> DateTime.add(-1*@seconds_in_day*n_days) |> DateTime.to_date()
    from p_v_d in TDB.Player_Village_Daily,
      where: p_v_d.day >= ^max_date,
      select: {p_v_d.player_id, p_v_d.village_id, p_v_d.day, p_v_d.race, p_v_d.population}
  end


  def get_all_historics(bad_n_days) do
    raise ArgumentError, message: "n_days must be >= 1 and is " <> Integer.to_string(bad_n_days)
  end
end
