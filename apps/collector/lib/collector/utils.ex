defmodule Collector.Utils do
  @milliseconds_in_day 24 * 60 * 60 * 1000

  @spec time_until_collection(collection_time :: Time.t()) :: non_neg_integer()
  def time_until_collection(collection_time) do
    now = Time.utc_now()

    case Time.compare(collection_time, now) do
      :eq -> 0
      :gt -> Time.diff(collection_time, now, :millisecond)
      :lt -> @milliseconds_in_day + Time.diff(now, collection_time, :millisecond)
    end
  end
end
