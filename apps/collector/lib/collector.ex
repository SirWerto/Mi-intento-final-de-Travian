defmodule Collector do
  @moduledoc """
  Documentation for `Collector`.
  """

  @typedoc """
  Url with http/https included
  """
  @type url :: String.t()

  @doc """
  Launch the collection process
  """
  @spec collect() :: :collect
  def collect(), do: Collector.GenCollector.collect()

  @doc """
  Hours until automatic collection process starts
  """
  @spec hours_until_collect() :: {:ok, float()} | {:error, :no_timer}
  def hours_until_collect(), do: Collector.GenCollector.hours_until_collect()

  @doc """
  Subscribe the process to the `Collector`. When a server is collected, the subscriber
  will receive {:collected, type, server_id}. It also monitors the `Collector`.
  """
  @spec subscribe() :: {:ok, reference()} | {:error, :no_timer}
  def subscribe(), do: Collector.GenCollector.subscribe()

  @doc """
  Unsubscribe and demonitor to `Collector`.
  """
  @spec unsubscribe(ref :: reference()) :: :ok | {:error, :no_timer}
  def unsubscribe(ref), do: Collector.GenCollector.unsubscribe(ref)



  @spec snapshot_to_format(snapshot :: [TTypes.enriched_row()]) :: binary()
  def snapshot_to_format(snapshot), do: :erlang.term_to_binary(snapshot, [:compressed, :deterministic])

  @spec snapshot_from_format(encoded_snapshot :: binary()) :: [TTypes.enriched_row()]
  def snapshot_from_format(encoded_snapshot), do: :erlang.binary_to_term(encoded_snapshot)


  @spec snapshot_errors_to_format(snapshot_errors :: [any()]) :: binary()
  def snapshot_errors_to_format(snapshot_errors), do: :erlang.term_to_binary(snapshot_errors, [:compressed, :deterministic])

  @spec snapshot_errors_from_format(encoded_snapshot_errors :: binary()) :: [any()]
  def snapshot_errors_from_format(encoded_snapshot_errors), do: :erlang.binary_to_term(encoded_snapshot_errors)


  @spec metadata_to_format(metadata :: map()) :: binary()
  def metadata_to_format(metadata), do: :erlang.term_to_binary(metadata, [:deterministic])

  @spec metadata_from_format(encoded_metadata :: binary()) :: map()
  def metadata_from_format(encoded_metadata), do: :erlang.binary_to_term(encoded_metadata)
end
