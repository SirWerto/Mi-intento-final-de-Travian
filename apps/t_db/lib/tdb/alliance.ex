defmodule TDB.Alliance do
  use Ecto.Schema

  @primary_key {:alliance_id, :string, []}

  schema "alliances" do
    field :name, :string
    
    #has_many :alliances_players, TDB.Alliance_Player, foreign_key: :alliance_id

    timestamps()
  end
end
