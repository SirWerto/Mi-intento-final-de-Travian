defmodule Front.MedusaView do
  use Front, :view

  @round 1

  @spec distance_to_COM(x :: float(), y :: float(), row :: Satellite.MedusaTable.t()) ::
          String.t()
  def distance_to_COM(x, y, row) do
    TTypes.distance401(x, y, row.center_mass_x, row.center_mass_y)
    |> Float.round(1)
    |> Float.to_string()
  end

  def mass_center_to_str(row) do
    x = Float.round(row.center_mass_x, @round)
    y = Float.round(row.center_mass_y, @round)
    "(#{x}|#{y})"
  end

  @spec max_attr(rows :: [Satellite.MedusaTable.t()], attr :: atom()) :: String.t()
  def max_attr(rows, attr) do
    Enum.max(rows, &(Map.fetch!(&1, attr) >= Map.fetch!(&2, attr))) |> Map.fetch!(attr)
  end

  def yesterday_to_string(:undefined), do: "undefined"
  def yesterday_to_string(true), do: "yes"
  def yesterday_to_string(false), do: "no"

  def today_to_string(true), do: "no"
  def today_to_string(false), do: "yes"

  @spec transparent_probability(probability :: float()) :: float()
  def transparent_probability(probability) do
    case probability do
      x when x < 0.3 -> 0.3
      x -> x
    end
  end
end
