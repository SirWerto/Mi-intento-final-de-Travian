defmodule GenWorkerTest do
  use ExUnit.Case

  @moduletag :capture_log

  test "stop and return normal when 3 attemps are reached" do
    server_id = "https://ts1.x1.asia.travian.com"
    max_tries = 3
    type = :info
    fake_timeref = ""
    state = {server_id, type, max_tries, fake_timeref}

    assert({:stop, :normal, state} == Collector.GenWorker.handle_info(:collect, state))
  end
end
