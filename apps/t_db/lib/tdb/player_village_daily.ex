defmodule TDB.Player_Village_Daily do
  use Ecto.Schema

  @primary_key false
  schema "players_villages_daily" do
    belongs_to :player, TDB.Player, primary_key: true
    belongs_to :village, TDB.Village, primary_key: true

    field :day, :date, primary_key: true
    field :race, :integer, null: false
    field :population , :integer, null: false

    timestamps()
  end
end
