defmodule TDB.Repo.Migrations.CreateServers do
  use Ecto.Migration

  def change do
    create table(:servers, primary_key: false) do
      add :id, :string, primary_key: true
      add :url, :string, null: false
      add :init_date, :date, null: false

      add :country , :string, size: 10
      add :worldId , :string
      add :speed , :integer
      add :appId , :string, null: true
      add :version , :string, null: true

      add :height , :integer
      add :bottom , :integer
      add :left , :integer
      add :right , :integer
      add :top , :integer
      add :width , :integer

      add :adventuresDecay , :boolean
      add :allianceBanner , :boolean
      add :allianceBonus , :boolean
      add :boostedStart , :boolean
      add :cities , :boolean
      add :contextHelp , :boolean
      add :factions , :boolean
      add :healHeroOnLevelUp , :boolean
      add :hideFoolsArtifacts , :boolean
      add :lockingRegionsAgain , :boolean
      add :multi_language , :boolean
      add :progressiveTasks , :boolean
      add :rearrangeBuildings , :boolean
      add :resourcesInHeroBag , :boolean
      add :sittingOnlyFriends , :boolean
      add :territory , :boolean
      add :travelOverTheWorldEdge , :boolean
      add :tribesEgyptiansAndHuns , :boolean
      add :useAdventureSpawnTime , :boolean
      add :vacationMode , :boolean

      timestamps()
    end
  end
end
