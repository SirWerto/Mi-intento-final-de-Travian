defmodule MedusaTrainTest do
  use ExUnit.Case
  doctest MedusaTrain

  test "greets the world" do
    assert MedusaTrain.hello() == :world
  end
end
