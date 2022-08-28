defmodule Satellite.MedusaTable do
  require Record

  @table_name :medusa_table

  @medusa_record {:medusa_row,
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
  }

  @enforce_keys [
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



  def create_table() do
  end

  @spec insert_predictions(medusa_structs :: [t()]) :: :ok | {:error, any()}
  def insert_predictions(medusa_structs) do
    :ok
  end

end
