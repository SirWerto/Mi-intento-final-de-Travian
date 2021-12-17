defmodule MedusaModelConsumerTest do
  use ExUnit.Case
  doctest MedusaModelConsumer

  test "start and stop MedusaModelConsumer" do
    models_dir = System.get_env("MEDUSA_MODEL_DIR")
    {:ok, consumer} = MedusaModelConsumer.start_link(models_dir <> "/medusa_model")
    assert(Process.alive?(consumer), "MedusaModelConsumer is not alive")
    MedusaModelConsumer.stop(consumer)
    assert(Process.alive?(consumer) == false, "MedusaModelConsumer is alive")
  end

  test "load good model" do
    models_dir = System.get_env("MEDUSA_MODEL_DIR")
    {port, _ref} = MedusaModelConsumerPort.open_port(models_dir <> "/medusa_model")
    true = MedusaModelConsumerPort.load_model(port)
    assert_receive({^port, {:data, "\"loaded\""}}, 2000, "not loaded")
  end


end
