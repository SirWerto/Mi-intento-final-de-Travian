defmodule TDB.Repo.Migrations.CreatePlayersVillagesDaily do
  use Ecto.Migration

  def change do
    create table(:players_villages_daily, primary_key: false) do
      add :player_id, references(:players, name: :player_id, column: :player_id, type: :string), primary_key: true
      add :village_id, references(:villages, name: :village_id, column: :village_id, type: :string), primary_key: true
      add :day, :date, primary_key: true
      add :race, :integer, null: false
      add :population , :integer, null: false

      timestamps()
    end

  end
end
