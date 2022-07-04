defmodule Step2 do
  @enforce_keys [
    :center_mass_x,
    :center_mass_y,
    :date,
    :distance_to_origin,
    :n_village_decrease,
    :n_village_increase,
    :n_villages,
    :player_id,
    :prev_distance_to_origin,
    :total_population,
    :total_population_decrease,
    :total_population_increase,
    :tribes_summary
  ]
  defstruct [
    :center_mass_x,
    :center_mass_y,
    :date,
    :distance_to_origin,
    :n_village_decrease,
    :n_village_increase,
    :n_villages,
    :player_id,
    :prev_distance_to_origin,
    :total_population,
    :total_population_decrease,
    :total_population_increase,
    :tribes_summary
  ]

  @type t :: %__MODULE__{
          player_id: TTypes.player_id(),
          date: Date.t(),
          total_population: pos_integer(),
          total_population_increase: non_neg_integer(),
          total_population_decrease: non_neg_integer(),
          n_villages: pos_integer(),
          n_village_increase: non_neg_integer(),
          n_village_decrease: non_neg_integer(),
          tribes_summary: TTypes.tribes_map(),
          center_mass_x: float(),
          center_mass_y: float(),
          distance_to_origin: float(),
          prev_distance_to_origin: float()
        }

  @spec process_2_snapshots([Step1.t()]) :: t()
  def process_2_snapshots([old, new]) do
    Enum.concat(old, new)
    |> Enum.group_by(fn s -> s.player_id end)
    |> Enum.map(&map_p/1)
  end

  defp map_p({_k, [first, last]}) do
    case Date.compare(first.date, last.date) do
      :lt -> p(first, last)
      :gt -> p(last, first)
    end
  end

  defp p(old, new) do
    {pop_inc, pop_dec} = compute_pop_diff(new.total_population - old.total_population)
    {n_v_inc, n_v_dec} = compute_n_v_diff(new.n_villages - old.n_villages)

    %__MODULE__{
      player_id: new.player_id,
      date: new.date,
      total_population: new.total_population,
      total_population_increase: pop_inc,
      total_population_decrease: pop_dec,
      n_villages: new.n_villages,
      n_village_increase: n_v_inc,
      n_village_decrease: n_v_dec,
      tribes_summary: new.tribes_summary,
      center_mass_x: new.center_mass_x,
      center_mass_y: new.center_mass_y,
      distance_to_origin: new.distance_to_origin,
      prev_distance_to_origin: old.distance_to_origin
    }
  end

  defp compute_pop_diff(0), do: {0, 0}
  defp compute_pop_diff(diff) when diff > 0, do: {diff, 0}
  defp compute_pop_diff(diff) when diff < 0, do: {0, -diff}

  defp compute_n_v_diff(0), do: {0, 0}
  defp compute_n_v_diff(diff) when diff > 0, do: {diff, 0}
  defp compute_n_v_diff(diff) when diff < 0, do: {0, -diff}
end
