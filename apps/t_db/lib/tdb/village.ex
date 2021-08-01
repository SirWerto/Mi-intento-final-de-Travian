defmodule TDB.Village do
  use Ecto.Schema

  @primary_key {:village_id, :string, []}

  schema "villages" do
    field :x, :integer, null: false
    field :y, :integer, null: false
    field :grid, :integer, null: false
    field :name, :string
    

    timestamps()
  end
end
