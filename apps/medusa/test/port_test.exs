defmodule PortTest do
  use ExUnit.Case


  test "Start port" do
    port_name = "port.py"
    model_name = "model_5_days.py"
    {port, ref} = Medusa.Port.start_monitor(port_name, model_name)
    assert(is_reference(ref), "Port bad monitored")
    Process.sleep(2000)
    assert(Port.info(port) != nil, "Port not correctly spawned")
  end


  test "Start port but no file" do
    port_name = "bad_port.py"
    model_name = "model_5_days.py"
    {port, _ref} = Medusa.Port.start_monitor(port_name, model_name)
    Process.sleep(2000)
    assert(Port.info(port) == nil, "Port not correctly spawned")
  end


  test "Init model" do
    port_name = "port.py"
    model_name = "model_5_days.py"
    {port, _ref} = Medusa.Port.start_monitor(port_name, model_name)
    Medusa.Port.load_model(port)
    assert_receive({^port, {:data, "\"loaded\""}}, 5_000, "Model not loaded")
  end


  test "Init bad model" do
    port_name = "port.py"
    model_name = "bad_model.py"
    {port, _ref} = Medusa.Port.start_monitor(port_name, model_name)
    Medusa.Port.load_model(port)
    assert_receive({^port, {:data, "\"not loaded\""}}, 5_000, "Bad response while bad model loaded")
  end


  # test "Init model but no model" do
  # end


  # test "Predict" do
  # end



end
