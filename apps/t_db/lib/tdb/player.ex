defmodule TDB.Player do
  use Ecto.Schema
  @primary_key {:id, :string, []}

  @type t :: %__MODULE__{
    id: String.t(),
    name:  String.t(),
    server_id: String.t(),
    inserted_at: NaiveDateTime.t(),
    updated_at: NaiveDateTime.t()
  }


  schema "players" do
    field :name, :string
    
    has_many :alliances_players, TDB.Alliance_Player, foreign_key: :player_id
    belongs_to :server, TDB.Server, type: :string
    timestamps()
  end
end
