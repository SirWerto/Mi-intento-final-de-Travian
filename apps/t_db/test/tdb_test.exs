defmodule TDBTest do
  use ExUnit.Case
  doctest TDB

  test "greets the world" do
    assert TDB.hello() == :world
  end
end
