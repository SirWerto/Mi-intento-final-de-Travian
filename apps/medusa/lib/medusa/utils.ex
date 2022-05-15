defmodule Medusa.Utils do

  def compute_inc_dec([first | rest]), do: compute_inc_dec(0, 0, first, rest)
  
  def compute_inc_dec(inc, dec, _prev, []), do: {inc, dec}
  def compute_inc_dec(inc, dec, prev, [next | rest]) do
    case prev - next do
		x when x >= 0 -> compute_inc_dec(inc + x, dec, next, rest)
		x  -> compute_inc_dec(inc, dec - x, next, rest)
    end
  end

  # @spec compute_inc_dec_village_pops(%)
  def compute_inc_dec_village_pops(vpops_new, vpops_old) do
    inverse_old = for {k, pop} <- vpops_old, into: %{}, do: {k, -pop}
    Map.merge(vpops_new, inverse_old, fn _key, v_new, v_old -> v_new + v_old end)
    |> Enum.reduce({0, 0}, fn {_k, v}, {inc, dec} when v >= 0 -> {inc + v, dec}
      {_k, v}, {inc, dec} -> {inc, dec - v} end)
  end




end
