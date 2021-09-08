defmodule TDB.Village do
  use Ecto.Schema

  @primary_key {:id, :string, []}


  @type t :: %__MODULE__{
    id: String.t(),
    server_id: String.t(),
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
    

    timestamps()
  end
end
