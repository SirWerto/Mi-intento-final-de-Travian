defmodule TDB.Alliance_Player do
  use Ecto.Schema

  schema "alliances_players" do
    belongs_to :player, TDB.Player, primary_key: true, references: :player_id
    belongs_to :alliance, TDB.Alliance, primary_key: true, references: :alliance_id

    timestamps()
  end
end
