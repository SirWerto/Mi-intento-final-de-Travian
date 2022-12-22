defmodule Front.MedusaView do
  use Front, :view

  @round 1

  @spec distance_to_COM(x :: float(), y :: float(), row :: Satellite.MedusaTable.t()) :: String.t()
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
end
