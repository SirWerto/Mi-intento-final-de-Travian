defmodule SatelliteTest do
  use ExUnit.Case
  doctest Satellite

  test "greets the world" do
    assert Satellite.hello() == :world
  end
end
