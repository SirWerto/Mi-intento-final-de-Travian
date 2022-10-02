defmodule MedusaMetrics do
  @moduledoc """
  Documentation for `MedusaMetrics`.
  """

  @metrics_options {"medusa_metrics", ".bert"}
  @failed_options {"medusa_failed", ".c6bert"}


  @spec metrics_options() :: {binary(), binary()}
  def metrics_options(), do: @metrics_options

  @spec metrics_to_format(metrics :: map()) :: binary()
  def metrics_to_format(metrics),
    do: :erlang.term_to_binary(metrics, [:deterministic])

  @spec metrics_from_format(encoded_metrics :: binary()) :: map()
  def metrics_from_format(encoded_metrics), do: :erlang.binary_to_term(encoded_metrics)


  @spec failed_options() :: {binary(), binary()}
  def failed_options(), do: @failed_options

  @spec failed_to_format(failed :: {TTypes.server_id(), TTypes.player_id()}) :: binary()
  def failed_to_format(failed),
    do: :erlang.term_to_binary(failed, [:deterministic])

  @spec failed_from_format(encoded_failed :: binary()) :: {TTypes.server_id(), TTypes.player_id()}
  def failed_from_format(encoded_failed), do: :erlang.binary_to_term(encoded_failed)

  @spec et(root_folder :: binary(), server_id :: TTypes.server_id(), target_date :: Date.t(), old_date :: Date.t()) :: {:ok, {MedusaMetrics.Metrics.t(), [MedusaMetrics.Failed.t()]}} | {:error, any()}
  def et(root_folder, server_id, target_date, old_date) do
    MedusaMetrics.ET.apply(root_folder, server_id, target_date, old_date)
  end


end
