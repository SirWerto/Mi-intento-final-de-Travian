defmodule Collector.Queries do
  require Logger

  @spec insert_or_update_server!(server_changeset :: Ecto.Changeset.t()) :: :ok
  def insert_or_update_server!(server_changeset) do
    TDB.Repo.insert!(server_changeset, on_conflict: :nothing)
  end

  @spec insert_or_update_players!(players_changesets :: [Ecto.Changeset.t()]) :: Ecto.Multi.t()
  def insert_or_update_players!(players_changesets) do
    Enum.reduce(players_changesets, Ecto.Multi.new(), &reducer_player/2)
  end

  @spec reducer_player(player_changeset :: Ecto.Changeset.t(), multi :: Ecto.Multi.t()) :: Ecto.Multi.t()
  defp reducer_player(player_changeset, multi) do
    opts = [on_conflict: {:replace, [:name, :updated_at]},
	    conflict_target: :id]
    Ecto.Multi.insert(multi, player_changeset.data.id, player_changeset, opts)
  end

  @spec insert_or_update_alliances!(alliances_changesets :: [Ecto.Changeset.t()]) :: Ecto.Multi.t()
  def insert_or_update_alliances!(alliances_changesets) do
    Enum.reduce(alliances_changesets, Ecto.Multi.new(), &reducer_alliance/2)
  end

  @spec reducer_alliance(alliance_changeset :: Ecto.Changeset.t(), multi :: Ecto.Multi.t()) :: Ecto.Multi.t()
  defp reducer_alliance(alliance_changeset, multi) do
    opts = [on_conflict: {:replace, [:name, :updated_at]},
	    conflict_target: :id]
    Ecto.Multi.insert(multi, alliance_changeset.data.id, alliance_changeset, opts)
  end

  @spec insert_or_update_villages!(villages_changesets :: [Ecto.Changeset.t()]) :: Ecto.Multi.t()
  def insert_or_update_villages!(villages_changesets) do
    Enum.reduce(villages_changesets, Ecto.Multi.new(), &reducer_village/2)
  end

  @spec reducer_village(village_changeset :: Ecto.Changeset.t(), multi :: Ecto.Multi.t()) :: Ecto.Multi.t()
  defp reducer_village(village_changeset, multi) do
    opts = [on_conflict: {:replace, [:name, :updated_at]},
	    conflict_target: :id]
    Ecto.Multi.insert(multi, village_changeset.data.id, village_changeset, opts)
  end

  @spec insert_or_update_a_p!(a_p_changesets :: [Ecto.Changeset.t()]) :: Ecto.Multi.t()
  def insert_or_update_a_p!(a_p_changesets) do
    Enum.reduce(a_p_changesets, Ecto.Multi.new(), &reducer_a_p/2)
  end

  @spec reducer_a_p(a_p_changeset :: Ecto.Changeset.t(), multi :: Ecto.Multi.t()) :: Ecto.Multi.t()
  defp reducer_a_p(a_p_changeset, multi) do
    opts = [on_conflict: :nothing]
    Ecto.Multi.insert(multi, a_p_changeset.data.player_id, a_p_changeset, opts)
  end

  @spec insert_or_update_p_v!(p_v_changesets :: [Ecto.Changeset.t()]) :: Ecto.Multi.t()
  def insert_or_update_p_v!(p_v_changesets) do
    Enum.reduce(p_v_changesets, Ecto.Multi.new(), &reducer_p_v/2)
  end

  @spec reducer_p_v(p_v_changeset :: Ecto.Changeset.t(), multi :: Ecto.Multi.t()) :: Ecto.Multi.t()
  defp reducer_p_v(p_v_changeset, multi) do
    opts = [on_conflict: :nothing]
    Ecto.Multi.insert(multi, p_v_changeset.data.village_id, p_v_changeset, opts)
  end
end
