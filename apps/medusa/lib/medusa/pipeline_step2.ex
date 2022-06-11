defmodule Medusa.Pipeline.Step2 do


  @enforce_keys [:fe_type, :fe_struct]
  @derive Jason.Encoder
  defstruct [:fe_type, :fe_struct]

  @type fe_type :: :ndays_1, :ndays_n
  @type fe_struct :: Medusa.Pipeline.FE1.t() | Medusa.Pipeline.FEN.t()

  @type t :: %__MODULE__{
    fe_type: fe_type(),
    fe_struct: fe_struct()
  }

  @spec remove_non_consecutive([Medusa.Pipeline.Step1.t()]) :: [Medusa.Pipeline.Step1.t()] | nil
  def remove_non_consecutive(step1_structs) do
    step1_structs
    |> Enum.sort_by(fn x -> x.date end, {:desc, Date})
    |> reduce_only_consecutive()
  end


  # @spec remove_non_consecutive([Medusa.Pipeline.Step1.t()]) :: [Medusa.Pipeline.Step1.t()] | nil
  # def remove_non_consecutive(step1_structs) do
  #   today = Date.utc_today()
  #   sorted = Enum.sort_by(step1_structs, fn x -> x.date end, {:desc, Date})
  #   case hd(sorted).date == today do
  #     false -> nil
  #     true -> reduce_only_consecutive(sorted)
  #   end
  # end

  # defp reduce_only_consecutive(sorted), do: reduce_only_consecutive([], sorted, Date.utc_today())
  defp reduce_only_consecutive(sorted), do: reduce_only_consecutive([], sorted, hd(sorted).date)

  defp reduce_only_consecutive(cons, [], _), do: cons
  defp reduce_only_consecutive(cons, [next | _], prev_date) when next.date != prev_date, do: cons
  defp reduce_only_consecutive(cons, [next | rest], prev_date), do: reduce_only_consecutive(cons ++ [next], rest, Date.add(prev_date, -1))


  @spec apply_FE([Medusa.Pipeline.Step1.t()]) :: t() | nil
  def apply_FE(step1_structs)
  def apply_FE(nil), do: nil
  def apply_FE([]), do: nil
  def apply_FE(structs = [_struct1]), do: %__MODULE__{fe_type: :ndays_1, fe_struct: Medusa.Pipeline.FE1.apply(structs)}
  def apply_FE(structs) when length(structs) <= 5, do: %__MODULE__{fe_type: :ndays_n, fe_struct: Medusa.Pipeline.FEN.apply(structs)}
  def apply_FE(structs), do: %__MODULE__{fe_type: :ndays_n, fe_struct: Medusa.Pipeline.FEN.apply(Enum.take(structs, 5))}
end
