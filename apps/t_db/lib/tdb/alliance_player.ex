defmodule TDB.Alliance_Player do
  use Ecto.Schema

  @primary_key false
  schema "alliances_players" do
    field :start_date, :date, primary_key: true
    belongs_to :player, TDB.Player, primary_key: true
    belongs_to :alliance, TDB.Alliance, primary_key: true
  end
end
