defmodule TDB.Repo.Migrations.CreatePlayersVillagesDaily do
  use Ecto.Migration

  def change do
    create table(:players_villages_daily, primary_key: false) do
      add :player_id, references(:players, type: :string), primary_key: true
      add :village_id, references(:villages, type: :string), primary_key: true
      add :day, :date, primary_key: true
      add :race, :integer, null: false
      add :population , :integer, null: false

      timestamps()
    end

  end
end
