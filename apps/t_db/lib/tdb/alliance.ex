defmodule TDB.Alliance do
  use Ecto.Schema

  @primary_key {:id, :string, []}

  @type t :: %__MODULE__{
    id: String.t(),
    name:  String.t(),
    server_id: String.t(),
    game_id: integer(),
    inserted_at: NaiveDateTime.t(),
    updated_at: NaiveDateTime.t()
  }

  schema "alliances" do
    field :name, :string
    field :game_id, :integer
    
    has_many :alliances_players, TDB.Alliance_Player, foreign_key: :alliance_id
    belongs_to :server, TDB.Server, type: :string
    timestamps()
  end

  def validate_from_travian_changeset(alliance, params \\ %{}) do
    alliance
    |> Ecto.Changeset.cast(params, [:id, :game_id, :server_id])
    |> Ecto.Changeset.validate_required([:id, :game_id, :server_id])
  end
end
