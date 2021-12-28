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

end
