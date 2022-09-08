defmodule UtilsTest do
  use ExUnit.Case

  @milliseconds_in_day 24 * 60 * 60 * 1000

  test "if the collection time is later, return the difference time in milliseconds" do
    collection_time = Time.utc_now() |> Time.add(3)
    wait_time = Collector.Utils.time_until_collection(collection_time)
    assert(wait_time > 0 and wait_time <= 3000)
  end

  test "if the collection time is earlier, return the next day collection time in milliseconds" do
    collection_time = Time.utc_now() |> Time.add(-3)
    wait_time = Collector.Utils.time_until_collection(collection_time)

    assert(
      wait_time > 0 and wait_time > @milliseconds_in_day and
        wait_time <= @milliseconds_in_day + 3000
    )
  end
end
