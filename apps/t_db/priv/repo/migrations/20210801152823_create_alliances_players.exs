defmodule TDB.Repo.Migrations.CreateAlliancesPlayers do
  use Ecto.Migration

  def change do
    create table(:alliances_players, primary_key: false) do
      add :player_id, references(:players, name: :player_id, column: :player_id, type: :string), primary_key: true
      add :alliance_id, references(:alliances, name: :alliance_id, column: :alliance_id, type: :string), primary_key: true

      timestamps()
    end
  end
end
