defmodule MedusaModels.Model5D do
  @moduledoc """
  Medusa 5 days model module for pipes and prediction
  """
  @year_cycle 2 * :math.pi() / 366

  @type tag() :: :active | :inactive | :future_inactive

  @type fe_output :: %{
          player_id: binary(),
          last_day: float(),
          weekend?: boolean(),
          pop_increase_day_1: non_neg_integer(),
          pop_increase_day_2: non_neg_integer(),
          pop_increase_day_3: non_neg_integer(),
          pop_increase_day_4: non_neg_integer(),
          max_races: pos_integer(),
          end_population: pos_integer(),
          total_decrease: integer()
        }

  @type output :: [fe_output()]
  @type output_train :: [{fe_output(), tag()}]

  @spec apply([MedusaPipeline.output()]) :: output()
  def apply(samples) do
    samples
    |> Enum.group_by(fn x -> x[:player] end)
    |> Enum.map(&pred_pipe_groupby/1)
    |> Enum.filter(&(!is_nil(&1)))
  end

  defp all_days_consecutive?(values_sorted) do
    values_sorted
    |> Enum.slice(0, 3)
    |> Enum.all?(fn x -> x[:next_day] == 1 end)
  end

  # @spec pred_pipe_groupby({Medusa.Types.player_id(), Medusa.Types.base_output()}) :: Medusa.Types.fe_5_output() | nil
  defp pred_pipe_groupby({_player_id, values}) when length(values) == 4 do
    sorted = Enum.sort_by(values, fn x -> x[:date] end, {:asc, Date})
    # last day is always consecutive
    case all_days_consecutive?(sorted) do
      true ->
        values
        |> List.to_tuple()
        |> fe()

      false ->
        nil
    end
  end

  defp pred_pipe_groupby({_player_id, _values}) do
    nil
  end

  @spec apply_train([MedusaPipeline.output()]) :: output_train()
  def apply_train(samples) do
    samples
    |> Enum.group_by(fn x -> x[:player] end)
    |> Enum.flat_map(&train_pipe_groupby/1)
    |> Enum.filter(&(!is_nil(&1)))
  end

  # @spec train_pipe_groupby({Medusa.Types.player_id(), Medusa.Types.base_output()}) ::
  # maybe_improper_list(Medusa.Types.train_5_out_tuple(), nil) | [nil]
  defp train_pipe_groupby(args)

  defp train_pipe_groupby({_player_id, values}) when length(values) >= 7 do
    values
    |> Enum.chunk_every(7, 1, :discard)
    |> Enum.map(&train_pipe_chunk/1)
  end

  defp train_pipe_groupby(_) do
    [nil]
  end

  # @spec train_pipe_chunk([Medusa.Types.base_output()]) :: Medusa.Types.train_5_out_tuple() | nil
  defp train_pipe_chunk(chunk) do
    sorted = Enum.sort_by(chunk, fn x -> x[:date] end, {:asc, Date})

    case Enum.slice(sorted, 0, 6) |> Enum.all?(fn x -> x[:next_day] == 1 end) do
      true ->
        fe =
          sorted
          |> Enum.slice(0, 4)
          |> List.to_tuple()
          |> fe()

        tag = eval_tag(sorted)
        {fe, tag}

      false ->
        nil
    end
  end

  # @spec eval_tag([Medusa.Types.base_output()]) :: tag()
  defp eval_tag(chunk) do
    case eval_inactive(chunk) do
      true ->
        :inactive

      false ->
        case eval_future_inactive(chunk) do
          true -> :future_inactive
          false -> :active
        end
    end
  end

  # @spec eval_inactive([Medusa.Types.base_output()]) :: boolean()
  defp eval_inactive(chunk) do
    chunk
    |> Enum.slice(2, 5)
    |> Enum.all?(fn x -> x[:population_increase] == 0 end)
  end

  # @spec eval_future_inactive([Medusa.Types.base_output()]) :: boolean()
  defp eval_future_inactive(chunk) do
    chunk
    |> Enum.slice(4, 3)
    |> Enum.all?(fn x -> x[:population_increase] == 0 end)
  end

  @doc """
  This function does the future engineer step betwen the sample(described below) and 
  the current model for 5 days.

  The sample must be 5 consecutive in days and same player_id maps from the base pipeline.
  """
  # @spec fe(Medusa.Types.fe_5_input()) :: Medusa.Types.fe_5_output()
  defp fe(sample = {_, _, _, last}) do
    %{
      player_id: last[:player],
      last_day: transform_day(last[:date]),
      weekend?: is_weekend?(last[:date]),
      pop_increase_day_1: Map.fetch!(elem(sample, 0), :population_increase),
      pop_increase_day_2: Map.fetch!(elem(sample, 1), :population_increase),
      pop_increase_day_3: Map.fetch!(elem(sample, 2), :population_increase),
      pop_increase_day_4: Map.fetch!(elem(sample, 3), :population_increase),
      max_races: max_races(sample),
      end_population: last[:population],
      total_decrease: total_decrease(sample)
    }
  end

  @spec is_weekend?(day :: Date.t()) :: boolean()
  defp is_weekend?(day) do
    Date.day_of_week(day) == 7
  end

  @spec transform_day(day :: Date.t()) :: float()
  defp transform_day(day) do
    y_day = Date.day_of_year(day)
    :math.sin(y_day * @year_cycle)
  end

  # @spec max_races(Medusa.Types.fe_5_input()) :: Medusa.Types.n_races()
  defp max_races(sample) do
    Enum.max(Tuple.to_list(sample), fn x, y -> x[:n_races] >= y[:n_races] end)
    |> Map.fetch!(:n_races)
  end

  # @spec total_decrease(Medusa.Types.fe_5_input()) :: Medusa.Types.population_decrease()
  defp total_decrease(sample) do
    Tuple.to_list(sample)
    |> Enum.map(fn x -> x[:population_decrease] end)
    |> Enum.sum()
  end
end
