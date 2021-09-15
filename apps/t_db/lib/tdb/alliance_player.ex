defmodule TDB.Alliance_Player do
  use Ecto.Schema

  @primary_key false
  schema "alliances_players" do
    field :start_date, :date, primary_key: true
    belongs_to :player, TDB.Player, primary_key: true, type: :string
    belongs_to :alliance, TDB.Alliance, primary_key: true, type: :string
  end



  def validate_from_travian_changeset(a_p, params \\ %{}) do
    a_p
    |> Ecto.Changeset.cast(params, [:player_id, :alliance_id, :start_date])
    |> Ecto.Changeset.validate_required([:player_id, :alliance_id, :start_date])
  end
end
