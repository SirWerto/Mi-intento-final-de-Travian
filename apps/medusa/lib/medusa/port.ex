defmodule Medusa.Port do
  @moduledoc """
  Documentation for `Medusa.Port`.
  """

  @python_version Application.compile_env!(:medusa, :python_version)

  @medusa_py "app.py"
  @medusa_py_env "medusa_env/lib/python#{@python_version}/site-packages"
  @medusa_model_1 "models/medusa_model_1.pkl"
  @medusa_model_n "models/medusa_model_n.pkl"


  @enforce_keys [:player_id, :inactive_in_future, :inactive_probability, :model]
  defstruct [:player_id, :inactive_in_future, :inactive_probability, :model]


  @type t :: %__MODULE__{
    player_id: TTypes.player_id(),
    inactive_in_future: boolean(),
    inactive_probability: float(),
    model: Medusa.model()}

  @spec open(model_dir :: String.t()) :: {port(), reference()}
  def open(model_dir) do

    python_path = model_dir <> "/" <> @medusa_py_env
    medusa_py = model_dir <> "/" <> @medusa_py
    medusa_model_1 = model_dir <> "/" <> @medusa_model_1
    medusa_model_n = model_dir <> "/" <> @medusa_model_n

    env = [{'PYTHONPATH', String.to_charlist(python_path)}]
    
    options = [
      :binary,
      {:packet, 4},
      {:env, env}
    ]

    port = Port.open({:spawn, "python#{@python_version} #{medusa_py} #{medusa_model_1} #{medusa_model_n}"}, options)
    ref = Port.monitor(port)
    
    {port, ref}
  end

  @spec close(port :: port(), ref :: reference()) :: :ok
  def close(port, ref) do
    Port.demonitor(ref, [:flush])
    send(port, {self(), :close})
    receive do
      {^port, :closed} -> :ok
      after
	3_000 -> :ok
    end
  end

  @spec predict!(port :: port, steps2 :: [Medusa.Pipeline.Step2.t()]) :: [t()]
  def predict!(port, steps2) do
    cmd = Jason.encode!(steps2)
    Port.command(port, cmd)
    receive do
      {^port, {:data, data}} ->
	for [model, player, pred, prob] <- Jason.decode!(data), do: map_port_to_struct(model, player, pred, prob)
    end
  end

  @spec map_port_to_struct(model :: String.t(), player :: TTypes.player_id(), pred :: String.t(), prob :: float()) :: t()
  defp map_port_to_struct(model, player, pred, prob) do
    %__MODULE__{
      player_id: player,
      inactive_in_future: pred,
      inactive_probability: prob,
      model: model_to_atom!(model)
    }
  end

  @spec model_to_atom!(String.t()) :: :player_1 | :player_n
  defp model_to_atom!("model_1"), do: :player_1
  defp model_to_atom!("model_n"), do: :player_n
end
