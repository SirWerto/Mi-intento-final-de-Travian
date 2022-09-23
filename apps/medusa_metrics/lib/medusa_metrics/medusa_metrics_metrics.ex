defmodule MedusaMetrics.Metrics do

  @enforce_keys [
    :total_players,
    :failed_players,
    :models,
    :target_date,
    :old_date,
    :square
  ]

  defstruct [
    :total_players,
    :failed_players,
    :models,
    :target_date,
    :old_date,
    :square
  ]

  @type t :: %__MODULE__{
    total_players: non_neg_integer(),
    failed_players: non_neg_integer(),
    models: %{Medusa.model() => MedusaMetrics.Models.t()},
    target_date: Date.t(),
    old_date: Date.t(),
    square: MedusaMetrics.Square.t()
  }



  @spec merge(x :: t(), y :: t()) :: t()
  def merge(x, y) when is_struct(x, __MODULE__) and is_struct(y, __MODULE__) do
    %__MODULE__{
      total_players: x.total_players + y.total_players,
      failed_players: x.failed_players + y.failed_players,
      target_date: x.target_date,
      old_date: x.old_date,
      models: Map.merge(x.models, y.models, fn _k, m1, m2 -> MedusaMetrics.Models.merge(m1, m2) end),
      square: MedusaMetrics.Square.merge(x.square, y.square)
    }
  end
end
