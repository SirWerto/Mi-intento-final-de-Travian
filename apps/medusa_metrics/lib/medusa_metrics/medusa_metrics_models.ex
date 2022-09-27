defmodule MedusaMetrics.Models do

  @enforce_keys [
    :model,
    :total_players,
    :failed_players,
    :square
  ]

  defstruct [
    :model,
    :total_players,
    :failed_players,
    :square
  ]

  @type t :: %__MODULE__{
          model: Medusa.model(),
	  total_players: non_neg_integer(),
	  failed_players: non_neg_integer(),
	  square: MedusaMetrics.Square.t()
        }

  @spec merge(x :: t(), y :: t()) :: t()
  def merge(x, y) when is_struct(x, __MODULE__) and is_struct(y, __MODULE__) do
    %__MODULE__{
      total_players: x.total_players + y.total_players,
      failed_players: x.failed_players + y.failed_players,
      model: x.model,
      square: MedusaMetrics.Square.merge(x.square, y.square)
    }
  end
end
