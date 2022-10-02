defmodule MedusaMetrics.Failed do

  @enforce_keys [
    :server_id,
    :player_id,
    :model,
    :target_date,
    :old_date,
    :expected,
    :result
  ]

  defstruct [
    :server_id,
    :player_id,
    :model,
    :target_date,
    :old_date,
    :expected,
    :result
  ]

  @type t :: %__MODULE__{
          server_id: TTypes.server_id(),
          player_id: TTypes.player_id(),
          model: Medusa.Pipeline.Step2.fe_type(),
          target_date: Date.t(),
          old_date: Date.t(),
	  expected: boolean(),
	  result: boolean()
        }
end
