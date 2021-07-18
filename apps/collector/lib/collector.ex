defmodule Collector do
  @moduledoc """
  Documentation for `Collector`.
  """

  @timeout 5000

  @typedoc """
  Url with http/https included
  """
  @type url :: String.t()

  @typedoc """
  Current urls results in status_table
  """
  @type url_status :: :waiting | :collecting | :done | :error

  @doc """
  Ask about the state of the collector, it could be `:waiting` or `:collecting`
  """
  @spec state?() :: {:ok, :waiting | :collecting} | {:error, :timeout}
  def state?() do
    try do
      case :gen_statem.call(Collector.Plubio, :current_state, 5000) do
	:waiting -> {:ok, :waiting}
	:collecting -> {:ok, :collecting}
      end
    rescue
      RuntimeError -> {:error, :timeout}
    end
  end


  @doc """
  Ask for the subscribers list of the collector
  """
  @spec subscribers() :: {:ok, [pid()]} | {:error, :timeout | any()}
  def subscribers() do
    try do
      :gen_statem.call(Collector.Plubio, :subscribers, @timeout)
    rescue
      RuntimeError -> {:error, :timeout}
    end
  end


  @doc """
  Subscribe to receive a message while the collecting process ends.
  
  The subscribed precess receive the following messages
  
  `:collecting_ends | {:collecting_error, reason}`
  """
  @spec subscribe(pid()) :: {:ok, :subscribed} | {:error, any()}
  def subscribe(spid) when is_pid(spid) do
    try do
      :gen_statem.call(Collector.Plubio, {:subscribe, spid}, @timeout)
    rescue
      RuntimeError -> {:error, :timeout}
    end
  end

  @spec subscribe(any()) :: {:error, :not_valid_pid}
  def subscribe(_bad_pid) do
    {:error, :not_valid_pid}
  end

  @doc """
  Unsubscribe from the collecting process list
  """
  @spec unsubscribe(pid()) :: {:ok, :unsubscribed} | {:error, :timeout}
  def unsubscribe(spid) when is_pid(spid) do
    try do
      :gen_statem.call(Collector.Plubio, {:unsubscribe, spid}, @timeout)
    rescue
      RuntimeError -> {:error, :timeout}
    end
  end

  @spec unsubscribe(any()) :: {:ok, :unsubscribed}
  def unsubscribe(_bad_pid) do
    {:ok, :unsubscribed}
  end


  @spec force_collecting() :: {:ok, :collecting} |  {:error, :timeout}
  def force_collecting() do
    try do
      :gen_statem.call(Collector.Plubio, :force_collecting, @timeout)
    rescue
      RuntimeError -> {:error, :timeout}
    end
  end

end
