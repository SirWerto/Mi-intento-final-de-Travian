defmodule MedusaMetrics.Square do

  @enforce_keys [
    :t_p,
    :t_n,
    :f_p,
    :f_n
  ]

  defstruct [
    :t_p,
    :t_n,
    :f_p,
    :f_n
  ]

  @type t :: %__MODULE__{
      t_p: non_neg_integer(),
      t_n: non_neg_integer(),
      f_p: non_neg_integer(),
      f_n: non_neg_integer()
        }


  @spec failed_players(square :: t()) :: non_neg_integer()
  def failed_players(square) when is_struct(square, __MODULE__) do
    square.f_n + square.f_p
  end

  @spec total_players(square :: t()) :: non_neg_integer()
  def total_players(square) when is_struct(square, __MODULE__) do
    square.t_n + square.f_p + square.t_p + square.f_n
  end

  @spec merge(x :: t(), y :: t()) :: t()
  def merge(x, y) when is_struct(x, __MODULE__) and is_struct(y, __MODULE__) do
    %__MODULE__{
      t_p: x.t_p + y.t_p,
      t_n: x.t_n + y.t_n,
      f_p: x.f_p + y.f_p,
      f_n: x.f_n + y.f_n
    }
  end

  @spec update(square :: t(), inactive_in_current :: bool(), inactive_in_future :: bool) :: t()
  def update(square, false, false) when is_struct(square, __MODULE__), do: Map.update!(square, :t_n, &(&1 + 1))
  def update(square, false, true) when is_struct(square, __MODULE__), do: Map.update!(square, :f_p, &(&1 + 1))
  def update(square, true, false) when is_struct(square, __MODULE__), do: Map.update!(square, :f_n, &(&1 + 1))
  def update(square, true, true) when is_struct(square, __MODULE__), do: Map.update!(square, :t_p, &(&1 + 1))
end
