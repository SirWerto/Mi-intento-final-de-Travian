defmodule Collector.Utils do

  @milliseconds_in_day 24*60*60*1000

  def time_until_collection(collection_hour), do: time_until_collection(collection_hour, Time.utc_now())
  defp time_until_collection(ch, ch), do: 0
  defp time_until_collection(ch, now) when ch > now, do: Time.diff(ch, now, :millisecond)
  defp time_until_collection(ch, now), do: @milliseconds_in_day + Time.diff(ch, now, :millisecond)
end
