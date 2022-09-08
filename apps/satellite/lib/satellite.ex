defmodule Satellite do
  @moduledoc """
  Documentation for `Satellite`.
  """

  @spec install(nodes :: [atom()]) :: :ok | {:error, any()}
  def install(nodes) do
    with(
      :rpc.multicall(nodes, :application, :stop, [:mnesia]),
      {:step_1, :ok} <- {:step_1, :mnesia.delete_schema(nodes)},
      {:step_2, :ok} <- {:step_2, :mnesia.create_schema(nodes)},
      :rpc.multicall(nodes, :application, :start, [:mnesia]),
      {:step_3, {:atomic, res}} <- {:step_3, Satellite.MedusaTable.create_table(nodes)}
    ) do
      :ok
    else
      reason -> {:error, reason}
    end
  end
end
