defmodule CollectorTest do
  use ExUnit.Case
  doctest Collector


  test "get current Collector state" do
    case Collector.state? do
      {:ok, :waiting} -> true
      {:ok, :collecting} -> true
      # {:error, :timeout} -> true
      _ -> raise "unexpected answer"
    end
  end

  test "get current subscribers" do
    case Collector.subscribers do
      {:ok, _subscribers} -> true
      # {:error, :timeout} -> true
      _ -> raise "unexpected answer"
    end
  end


  test "subscribe" do
    case Collector.subscribe(self()) do
      {:ok, :subscribed} -> true
      {:error, :not_valid_pid} -> raise "pid is a bad pid?"
      # {:error, :timeout} -> true
      _ -> raise "unexpected answer"
    end
  end

  test "subscribe with bad pid" do
    case Collector.subscribe(:bad_pid) do
      {:error, :not_valid_pid} -> true
      # {:error, :timeout} -> true
      _ -> raise "unexpected answer"
    end
  end

  test "unsubscribe" do
    {:ok, :subscribed} = Collector.subscribe(self())
    {:ok, :unsubscribed} = Collector.unsubscribe(self())
  end

  test "unsubscribe without subscribe" do
    {:ok, :unsubscribed} = Collector.unsubscribe(self())
  end

  test "unsubscribe with bad pid" do
    {:ok, :unsubscribed} = Collector.unsubscribe(:bad_pid)
  end

  test "force collecting" do
    {:ok, :collecting} = Collector.force_collecting()
  end

  test "force collecting change state" do
    {:ok, :waiting} = Collector.state?()
    {:ok, :collecting} = Collector.force_collecting()
    {:ok, :collecting} = Collector.state?()
  end


end
