defmodule Collector do
  @moduledoc """
  Documentation for `Collector`.
  """

  @typedoc """
  Url with http/https included
  """
  @type url :: String.t()

  @doc """
  Force start the whole collecting precess
  """
  def force_collect() do
    GenServer.call(Collector.Plubio, :force_collect)
  end


  @doc """
  Ask about the ending of the collection precess
  """
  def is_done?() do
   :ok 
  end

  @doc """
  Subscribe to receive a message while the collecting process ends.
  
  The subscribed precess receive the following messages
  
  `:collecting_ends | {:collecting_error, reason}`
  """
  @spec subscribe(pid()) :: :subscribed | {:error, any()}
  def subscribe(spid) do
    GenServer.call(Collector.Plubio, {:subscribe, spid})
  end

  @doc """
  Unsubscribe from the collecting process list
  """
  @spec unsubscribe(pid()) :: :unsubscribed | {:error, any()}
  def unsubscribe(spid) do
    GenServer.call(Collector.Plubio, {:unsubscribe, spid})
  end

end
