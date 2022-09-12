defmodule MedusaMetrics.Models do

  @enforce_keys [
    :model,
    :total_players,
    :failed_players
  ]

  defstruct [
    :model,
    :total_players,
    :failed_players
  ]

  @type t :: %__MODULE__{
          model: Medusa.models(),
	  total_players: non_neg_integer(),
	  failed_players: non_neg_integer()
        }

  @spec merge(x :: t(), y :: t()) :: t()
  def merge(x, y) do
    %__MODULE__{
      total_players: x.total_players + y.total_players,
      failed_players: x.failed_players + y.failed_players,
      model: x.model
    }
  end
end
