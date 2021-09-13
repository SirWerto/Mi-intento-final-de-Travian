defmodule TDB.Repo.Migrations.CreateAlliances do
  use Ecto.Migration

  def change do
    create table(:alliances, primary_key: false) do
      add :id, :string, primary_key: true
      add :server_id, references(:servers, type: :string), null: false
      add :game_id, :integer, null: false
      add :name, :string

      timestamps()
    end
  end
end
