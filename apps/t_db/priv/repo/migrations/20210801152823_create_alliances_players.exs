defmodule TDB.Repo.Migrations.CreateAlliancesPlayers do
  use Ecto.Migration

  def change do
    create table(:alliances_players, primary_key: false) do
      add :player_id, references(:players, type: :string), primary_key: true
      add :alliance_id, references(:alliances, type: :string), primary_key: true
      add :start_date, :date, primary_key: true
    end
  end
end
