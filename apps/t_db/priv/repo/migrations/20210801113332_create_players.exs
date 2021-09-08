defmodule TDB.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players, primary_key: false) do
      add :id, :string, primary_key: true
      add :server_id, references(:servers, type: :string), null: false
      add :name, :string

      timestamps()
    end
  end
end
