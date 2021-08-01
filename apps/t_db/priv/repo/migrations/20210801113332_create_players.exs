defmodule TDB.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players, primary_key: false) do
      #add :server_id, references(:servers, name: :server_id, column: :server_id, type: :string), primary_key: true
      add :player_id, :string, primary_key: true
      add :name, :string

      timestamps()
    end
  end
end
