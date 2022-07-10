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
end
