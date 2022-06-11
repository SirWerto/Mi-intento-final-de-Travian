defmodule Medusa.Pipeline do

  @spec apply([{Date.t(), [TTypes.enriched_row]}]) :: [Medusa.Pipeline.Step2.t()]
  def apply(snapshots) do
    snapshots
    |> Enum.flat_map(&Medusa.Pipeline.Step1.process_snapshot/1)
    |> Enum.group_by(fn x -> x.player_id end)
    |> Enum.map(fn {_key, value} -> remove_non_consecutive_and_apply_FE(value) end)
    |> Enum.filter(fn x -> x != nil end)
  end


  @spec remove_non_consecutive_and_apply_FE([Medusa.Pipeline.Step1.t()]) :: Medusa.Pipeline.Step2.t() | nil
  defp remove_non_consecutive_and_apply_FE(step1_structs) do
    today = Date.utc_today()
    step1_structs
    |> Medusa.Pipeline.Step2.remove_non_consecutive()
    |> Enum.filter(fn [head | _] -> head.date == today end)
    |> Medusa.Pipeline.Step2.apply_FE()
  end


  ## It should use the whole sample, but for the moment just keep the consecutive days
  @spec get_train_data([{Date.t(), [TTypes.enriched_row]}]) :: [{Medusa.player_status(), Medusa.Pipeline.Step2.t()}]
  def get_train_data(snapshots) do
    snapshots
    |> Enum.flat_map(&Medusa.Pipeline.Step1.process_snapshot/1)
    |> Enum.group_by(fn x -> x.player_id end)
    |> Enum.flat_map(fn {_player_id, step1_structs} ->
      step1_structs
      |> Medusa.Pipeline.Step2.remove_non_consecutive()
      |> get_chunks()
      |> Enum.map(&assign_status/1)
    end)
  end

  defp get_chunks(structs) do
    Enum.reduce([
      Enum.chunk_every(structs, 3, 1, :discard),
      Enum.chunk_every(structs, 4, 1, :discard),
      Enum.chunk_every(structs, 5, 1, :discard),
      Enum.chunk_every(structs, 6, 1, :discard),
      Enum.chunk_every(structs, 7, 1, :discard)
      ], fn x, acc -> acc ++ x end)
  end

  defp assign_status(chunk) do
    sorted = Enum.sort_by(chunk, fn x -> x.date end, {:desc, Date})
    [last_day | [day_minus_one | eval = [day_minus_two | _]]] = sorted
    %{
      inactive_in_future: is_inactive(day_minus_two, day_minus_one, last_day),
      sample: Medusa.Pipeline.Step2.apply_FE(eval)
    }
  end

  @doc """
  A player is inactive if the last 3 days she/he has not increased the population in any of his/her villages.
  """
  @spec is_inactive(day_minus_two :: Medusa.Pipeline.Step1.t(), day_minus_one :: Medusa.Pipeline.Step1.t(), current_day :: Medusa.Pipeline.Step1.t()) :: boolean()
  def is_inactive(day_minus_two, day_minus_one, current_day) do
    village_old_2_day = day_minus_two.village_pop
    village_old_1_day = day_minus_one.village_pop
    village_current_day = current_day.village_pop

    case active_day?(village_old_2_day, village_old_1_day) do
      true ->
	false
      false -> !active_day?(village_old_1_day, village_current_day)
    end
  end

  @spec active_day?(villages_old_day :: %{String.t() => pos_integer()}, villages_new_day :: %{String.t() => pos_integer()}) :: boolean()
  def active_day?(villages_old_day, villages_new_day) do
    any_vill_increase?(villages_old_day, villages_new_day) or any_pop_increase?(villages_old_day, villages_new_day)
  end

  @spec any_pop_increase?(villages_old_day :: %{String.t() => pos_integer()}, villages_new_day :: %{String.t() => pos_integer()}) :: boolean()
  defp any_pop_increase?(villages_old_day, villages_new_day) do
    inverse_old = for {k, pop} <- villages_old_day, into: %{}, do: {k, -pop}
    joined = Map.merge(villages_new_day, inverse_old, fn _key, v_new, v_old -> v_new + v_old end)
    Enum.any?(joined, fn {_k, v} -> v > 0 end)
  end

  @spec any_vill_increase?(villages_old_day :: %{String.t() => pos_integer()}, villages_new_day :: %{String.t() => pos_integer()}) :: boolean()
  defp any_vill_increase?(villages_old_day, villages_new_day) do
    vill_old = Map.keys(villages_old_day)
    vill_new = Map.keys(villages_new_day)
    !Enum.all?(vill_new, fn vnew -> vnew in vill_old end)
  end

end

