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
  @spec collect() :: :ok
  def collect(), do: Collector.GenCollector.collect()

  @doc """
  Subscribe the process to the `Collector`. When a server is collected, the subscriber
  will receive {:collected, type, server_id}. It also monitors the `Collector`.
  """
  @spec subscribe() :: reference()
  def subscribe(), do: Collector.GenCollector.subscribe()

  @spec etl_snapshot(root_folder :: binary(), server_id :: TTypes.server_id()) ::
          :ok | {:error, any()}
  def etl_snapshot(root_folder, server_id),
    do: Collector.GenWorker.Snapshot.etl(root_folder, server_id)

  @spec etl_metadata(root_folder :: binary(), server_id :: TTypes.server_id()) ::
          :ok | {:error, any()}
  def etl_metadata(root_folder, server_id),
    do: Collector.GenWorker.Metadata.etl(root_folder, server_id)

  @spec snapshot_to_format(snapshot :: [TTypes.enriched_row()]) :: binary()
  def snapshot_to_format(snapshot),
    do: :erlang.term_to_binary(snapshot, [:compressed, :deterministic])

  @spec snapshot_from_format(encoded_snapshot :: binary()) :: [TTypes.enriched_row()]
  def snapshot_from_format(encoded_snapshot), do: :erlang.binary_to_term(encoded_snapshot)

  @spec snapshot_errors_to_format(snapshot_errors :: [any()]) :: binary()
  def snapshot_errors_to_format(snapshot_errors),
    do: :erlang.term_to_binary(snapshot_errors, [:compressed, :deterministic])

  @spec snapshot_errors_from_format(encoded_snapshot_errors :: binary()) :: [any()]
  def snapshot_errors_from_format(encoded_snapshot_errors),
    do: :erlang.binary_to_term(encoded_snapshot_errors)

  @spec raw_snapshot_to_format(raw_snapshot :: binary()) :: binary()
  def raw_snapshot_to_format(raw_snapshot),
    do: :erlang.term_to_binary(raw_snapshot, [:compressed, :deterministic])

  @spec raw_snapshot_from_format(encoded_raw_snapshot :: binary()) :: binary()
  def raw_snapshot_from_format(encoded_raw_snapshot),
    do: :erlang.binary_to_term(encoded_raw_snapshot)

  @spec metadata_to_format(metadata :: map()) :: binary()
  def metadata_to_format(metadata), do: :erlang.term_to_binary(metadata, [:deterministic])

  @spec metadata_from_format(encoded_metadata :: binary()) :: map()
  def metadata_from_format(encoded_metadata), do: :erlang.binary_to_term(encoded_metadata)

  @spec players_snapshot_to_format(players_snapshot :: [Collector.PlayersSnapshot.t()]) ::
          binary()
  def players_snapshot_to_format(players_snapshot),
    do: :erlang.term_to_binary(players_snapshot, [:compressed, :deterministic])

  @spec players_snapshot_from_format(encoded_players_snapshot :: binary()) :: [
          Collector.PlayersSnapshot.t()
        ]
  def players_snapshot_from_format(encoded_players_snapshot),
    do: :erlang.binary_to_term(encoded_players_snapshot)

  @spec server_metadata_to_format(server_metadata :: Collector.ServerMetadata.t()) :: binary()
  def server_metadata_to_format(server_metadata), do: :erlang.term_to_binary(server_metadata, [:deterministic])

  @spec server_metadata_from_format(encoded_server_metadata :: binary()) :: Collector.ServerMetadata.t()
  def server_metadata_from_format(encoded_server_metadata), do: :erlang.binary_to_term(encoded_server_metadata)


  def snapshot_options(), do: {"snapshot", ".c6bert"}
  def snapshot_errors_options(), do: {"snapshot_errors", ".c6bert"}
  def raw_snapshot_options(), do: {"raw_snapshot", ".c6bert"}
  def metadata_options(), do: {"metadata", ".bert"}
  def server_metadata_options(), do: {"server_metadata", ".bert"}
  def players_snapshot_options(), do: {"players_snapshot", ".c6bert"}
end
