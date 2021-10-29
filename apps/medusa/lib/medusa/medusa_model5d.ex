defmodule Medusa.Model5D do

  @moduledoc """
  Medusa 5 days model module for pipes and prediction
  """

  @spec pred_pipe(Medusa.Types.pred_5_input()) :: Medusa.Types.pred_5_output()
  def pred_pipe(samples) do
    samples
    |> Enum.group_by(fn x -> x[:player] end)
    |> Enum.map(&pred_pipe_groupby/1)
    |> Enum.filter(fn
      nil -> false
      _x -> true end)
  end

  @spec pred_pipe_groupby({Medusa.Types.player_id(), Medusa.Types.base_output()}) :: Medusa.Types.fe_5_output() | nil
  defp pred_pipe_groupby({_player_id, values}) when length(values) == 4 do
    sorted = Enum.sort_by(values, fn x -> x[:date] end, {:asc, Date}) 
    case Enum.slice(sorted, 0, 3) |> Enum.all?(fn x -> x[:next_day]==1 end) do # last day is always consecutive
      true ->
	values
	|> List.to_tuple()
	|> Medusa.Model5D.FE.extract()
      false -> nil
    end
  end
  defp pred_pipe_groupby({_player_id, _values}) do
    nil
  end


  @spec train_pipe(Medusa.Types.train_5_input()) :: Medusa.Types.train_5_out()
  def train_pipe(samples) do
    samples
    |> Enum.group_by(fn x -> x[:player] end)
    |> Enum.flat_map(&train_pipe_groupby/1)
    |> Enum.filter(fn
      nil -> false
      _x -> true end)
  end

  @spec train_pipe_groupby({Medusa.Types.player_id(), Medusa.Types.base_output()}) ::
  maybe_improper_list(Medusa.Types.train_5_out_tuple(), nil) | [nil]
  defp train_pipe_groupby(args)
  defp train_pipe_groupby({_player_id, values}) when length(values) >= 7 do
    values
    |> Enum.chunk_every(7, 1, :discard)
    |> Enum.map(&train_pipe_chunk/1)
  end
  defp train_pipe_groupby(_) do
    [nil]
  end

  @spec train_pipe_chunk([Medusa.Types.base_output()]) :: Medusa.Types.train_5_out_tuple() | nil
  defp train_pipe_chunk(chunk) do
    sorted = Enum.sort_by(chunk, fn x -> x[:date] end, {:asc, Date})
    case Enum.slice(sorted, 0, 6) |> Enum.all?(fn x -> x[:next_day]==1 end) do
      true ->
	fe = sorted
	|> Enum.slice(0, 4)
	|> List.to_tuple()
	|> Medusa.Model5D.FE.extract()
	tag = eval_tag(sorted)
	{fe, tag}
      false -> nil
    end
  end

  @spec eval_tag([Medusa.Types.base_output()]) :: Medusa.Types.tag()
  defp eval_tag(chunk) do
    case eval_inactive(chunk) do
      true -> :inactive
      false -> case eval_future_inactive(chunk) do
		 true -> :future_inactive
		 false -> :active
	       end
    end
  end

  @spec eval_inactive([Medusa.Types.base_output()]) :: boolean()
  defp eval_inactive(chunk) do
    chunk
    |> Enum.slice(2, 5)
    |> Enum.all?(fn x -> x[:population_increase] == 0 end)
  end

  @spec eval_future_inactive([Medusa.Types.base_output()]) :: boolean()
  defp eval_future_inactive(chunk) do
    chunk
    |> Enum.slice(4, 3)
    |> Enum.all?(fn x -> x[:population_increase] == 0 end)
  end

end
