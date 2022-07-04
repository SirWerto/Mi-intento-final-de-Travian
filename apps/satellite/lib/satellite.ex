defmodule Satellite do
  @moduledoc """
  Documentation for `Satellite`.
  """

  @spec send_medusa_predictions(enriched_predictions :: map()) :: :ok | {:error, any()}
  def send_medusa_predictions(enriched_predictions) do
    IO.inspect(enriched_predictions)
  end
end
