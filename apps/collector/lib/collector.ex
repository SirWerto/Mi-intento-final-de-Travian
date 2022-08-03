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



  @spec snapshot_to_format(snapshot :: [TTypes.enriched_row()]) ::
          {:ok, binary()} | {:error, any()}
  def snapshot_to_format(snapshot) do
    case Jason.encode(snapshot) do
      {:error, reason} -> {:error, reason}
      {:ok, json} -> {:ok, :zlib.gzip(json)}
    end
  end


  @spec snapshot_from_format(encoded_info :: binary()) ::
          {:ok, [TTypes.enriched_row()]} | {:error, any()}
  def snapshot_from_format(snapshot) do
    snapshot
    |> :zlib.gunzip()
    |> Jason.decode(keys: :atoms!)
  end
end
