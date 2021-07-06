defmodule CollectorTest do
  use ExUnit.Case
  doctest Collector

  test "greets the world" do
    assert Collector.hello() == :world
  end
end
