defmodule TDB.Village do
  use Ecto.Schema

  @primary_key {:id, :string, []}


  @type t :: %__MODULE__{
    id: String.t(),
    server_id: String.t(),
    game_id: integer(),
    name:  String.t(),
    x: integer(),
    y: integer(),
    grid: integer(),
    inserted_at: NaiveDateTime.t(),
    updated_at: NaiveDateTime.t()
  }

  schema "villages" do
    belongs_to :server, TDB.Server, type: :string
    field :x, :integer, null: false
    field :y, :integer, null: false
    field :grid, :integer, null: false
    field :name, :string
    field :game_id, :integer
    

    timestamps()
  end


  def validate_from_travian_changeset(village, params \\ %{}) do
    village
    |> Ecto.Changeset.cast(params, [:id, :game_id, :server_id, :x, :y, :grid])
    |> Ecto.Changeset.validate_required([:id, :game_id, :server_id, :x, :y, :grid])
    |> Ecto.Changeset.validate_number(:grid, greater_than_or_equal_to: 0) #test
  end
end
