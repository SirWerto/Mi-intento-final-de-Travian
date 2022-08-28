defmodule Satellite.MedusaTable do
  require Record

  @table_name :medusa_table

  @medusa_record {:medusa_row, :server_id, :server_url, :player_id, :player_name, :player_url,
                  :alliance_id, :alliance_name, :alliance_url, :inactive_in_future,
                  :inactive_in_current, :total_population, :model, :n_villages, :target_date,
                  :creation_dt}

  @enforce_keys [
    :server_id,
    :server_url,
    :player_id,
    :player_name,
    :player_url,
    :alliance_id,
    :alliance_name,
    :alliance_url,
    :inactive_in_future,
    :inactive_in_current,
    :total_population,
    :model,
    :n_villages,
    :target_date,
    :creation_dt
  ]

  defstruct [
    :server_id,
    :server_url,
    :player_id,
    :player_name,
    :player_url,
    :alliance_id,
    :alliance_name,
    :alliance_url,
    :inactive_in_future,
    :inactive_in_current,
    :total_population,
    :model,
    :n_villages,
    :target_date,
    :creation_dt
  ]

  @type t :: %__MODULE__{
          server_id: TTypes.server_id(),
          server_url: binary(),
          player_id: TTypes.player_id(),
          player_name: TTypes.player_name(),
          player_url: binary(),
          alliance_id: TTypes.alliance_id(),
          alliance_name: TTypes.alliance_name(),
          alliance_url: binary(),
          inactive_in_future: boolean() | :undefined,
          inactive_in_current: boolean(),
          total_population: pos_integer(),
          model: Medusa.Pipeline.Step2.fe_type(),
          n_villages: pos_integer(),
          target_date: Date.t(),
          creation_dt: DateTime.t()
        }

  def create_table(nodes) do
  end

  @spec create_bank_players_table(nodes :: [atom()]) :: {:atomic, any()} | {:aborted, any()}
  defp create_bank_players_table(nodes) do
    bank_players_options = [
      attributes: [
        :player_id,
        :server_url,
        :player_name,
        :alliance_name,
        :n_villages,
        :total_popultaion,
        :state,
        :date
      ],
      disc_copies: nodes,
      index: [:server_url, :state],
      type: :set
    ]

    :mnesia.create_table(:bank_players, bank_players_options)
  end

  @spec insert_predictions(medusa_structs :: [t()]) :: :ok | {:error, any()}
  def insert_predictions(medusa_structs) do
    :ok
  end
end
