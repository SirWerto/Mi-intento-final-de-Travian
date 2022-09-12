defmodule MedusaMetrics.Metrics do

  @enforce_keys [
    :total_players,
    :failed_players,
    :models,
    :target_date,
    :old_date
  ]

  defstruct [
    :total_players,
    :failed_players,
    :models,
    :target_date,
    :old_date
  ]

  @type t :: %__MODULE__{
    total_players: non_neg_integer(),
    failed_players: non_neg_integer(),
    models: %{Medusa.model() => MedusaMetrics.Models.t()},
    target_date: Date.t(),
    old_date: Date.t()
  }


  # @spec merge(x :: t(), y :: t()) :: t()
  # def merge(x, y) do
  #   %__MODULE__{
  #     total_players: x.total_players + y.total_players,
  #     failed_players: x.failed_players + y.failed_players,
  #     target_date: x.target_date,
  #     old_date: x.old_date,
  #     models: merge_models(x.models, y.models)
  #   }
  # end

  # @spec merge_models(x :: %{MedusaMetrics.Models.t()}, y :: %{MedusaMetrics.Models.t()}) :: %{MedusaMetrics.Models.t()}
  # defp merge_models(x, y) do
  # end
end
