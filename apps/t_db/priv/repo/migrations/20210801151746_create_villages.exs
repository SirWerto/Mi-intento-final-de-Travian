defmodule TDB.Repo.Migrations.CreateVillages do
  use Ecto.Migration

  def change do
    create table(:villages, primary_key: false) do
      add :id, :string, primary_key: true
      add :server_id, references(:servers, type: :string), null: false
      add :x, :integer, null: false
      add :y, :integer, null: false
      add :grid , :integer, null: false
      add :name, :string

      timestamps()
    end
  end
end
