defmodule TDB.Player do
  use Ecto.Schema

  @primary_key {:player_id, :string, []}

  schema "players" do
    field :name, :string
    
    #belongs_to :server, TDB.Server, primary_key: true, references: :server_id
    timestamps()
  end
end
