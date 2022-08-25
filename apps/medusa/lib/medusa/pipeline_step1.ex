defmodule Medusa.Pipeline.Step1 do
  
  @enforce_keys [:player_id, :date, :total_population, :n_villages, :village_pop, :tribes_summary, :center_mass_x, :center_mass_y, :distance_to_origin]
  defstruct [:player_id, :date, :total_population, :n_villages, :village_pop, :tribes_summary, :center_mass_x, :center_mass_y, :distance_to_origin]
  
  @type t :: %__MODULE__{
    player_id: TTypes.player_id(),
    date: Date.t(),
    total_population: pos_integer(),
    n_villages: pos_integer(),
    village_pop: %{TTypes.village_id() => pos_integer()},
    tribes_summary: TTypes.tribes_map(),
    center_mass_x: float(),
    center_mass_y: float(),
    distance_to_origin: float()}
  
  
  @tribe_map %{
    1 => :romans,
    2 => :teutons,
    3 => :gauls,
    4 => :nature,
    5 => :natars,
    6 => :huns,
    7 => :egyptians
  }
  
  @spec process_snapshot({Date.t(), [Collector.SnapshotRow.t()]}) :: [t()]
  def process_snapshot({date, enriched_rows}) do
    enriched_rows
    |> Enum.group_by(fn row -> row.player_id end)
    |> Enum.map(fn {_k,v} -> p(date, v) end)
  end
  
  
  defp p(date, snapshot_rows = [first | _]) do
    points = for row <- snapshot_rows, do: {row.x, row.y}
    {center_mass_x, center_mass_y} = center_mass(points)
    %__MODULE__{
      player_id: first.player_id,
      date: date,
      total_population: Enum.map(snapshot_rows, fn row -> row.population end) |> Enum.sum(),
      n_villages: length(snapshot_rows),
      village_pop: (for row <- snapshot_rows, into: %{}, do: {row.village_id, row.population}),
      tribes_summary: tribe_summary(snapshot_rows),
      center_mass_x: center_mass_x,
      center_mass_y: center_mass_y,
      distance_to_origin: distance_to_origin(center_mass_x, center_mass_y)
    }
  end
  
  defp tribe_summary(row) do
    f = fn row -> row.tribe end
    row
    |> Enum.group_by(f, f)
    |> Enum.map(fn {tribe, v} -> {@tribe_map[tribe], length(v)} end)
    |> Enum.into(%{})
  end
  
  defp center_mass(points) do
    {x, y, l} = Enum.reduce(points, {0, 0, 0}, fn {x, y}, {acc1, acc2, acc3} -> {acc1+x, acc2+y, acc3+1} end)
    {x/l, y/l}
  end
  
  defp distance_to_origin(x, y) do
    :math.sqrt(:math.pow(x, 2) + :math.pow(y, 2))
    |> Float.round(2)
  end
  
  
  
  # :math.sqrt()
  # :math.pow()
end
