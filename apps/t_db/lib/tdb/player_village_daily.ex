defmodule TDB.Player_Village_Daily do
  use Ecto.Schema

  @primary_key false
  schema "players_villages_daily" do
    belongs_to :player, TDB.Player, primary_key: true
    belongs_to :village, TDB.Village, primary_key: true

    field :day, :date, primary_key: true
    field :race, :integer, null: false
    field :population , :integer, null: false

    timestamps()
  end


  def changeset(p_v_d, params \\ %{}) do
    p_v_d
    |> Ecto.Changeset.cast(params, [:player_id, :village_id, :day, :race, :population])
    |> Ecto.Changeset.validate_required([:player_id, :village_id, :day, :race, :population])
    |> Ecto.Changeset.validate_number([:population, :race], greater_than_or_equal_to: 1) #test
    # Population has to be equal o more than 1, because you can't destroy village
    # Race start on 1
  end
end
