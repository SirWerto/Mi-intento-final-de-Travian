defmodule Medusa.Test do
  use ExUnit.Case


  test "if Medusa receive a {:collector_event, :collection_started} notification, it will forward {:medusa_event, :prediction_started}" do
  end


  test "if Medusa ends the predictions, it will forward {:medusa_event, :prediction_finished}" do
  end


  test "if Medusa predicts a server, it will forward {:medusa_event, {:prediction_done, server_id}} in case of success" do
  end


  test "if Medusa predicts a server, it will forward {:medusa_event, {:prediction_failed, server_id}} in case of failure" do
  end


  test "if Medusa receive a {:collector_event, {:snapshot_collected, server_id}} notification while active, it will make the prediction of the server_id and store it" do
  end

end
