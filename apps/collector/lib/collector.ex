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

end
