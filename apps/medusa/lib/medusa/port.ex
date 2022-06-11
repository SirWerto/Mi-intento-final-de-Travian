defmodule Medusa.Port do
  @moduledoc """
  Documentation for `Medusa.Port`.
  """

  @medusa_py "medusa_app.py"
  @medusa_py_env "medusa_env/lib/python3.7/site-packages"
  @medusa_model_1 "medusa_model_1.pkl"
  @medusa_model_n "medusa_model_n.pkl"


  @enforce_keys [:player_id, :inactive_in_future, :model]
  defstruct [:player_id, :inactive_in_future, :model]


  @type t :: %__MODULE__{
    player_id: TTypes.player_id(),
    inactive_in_future: boolean(),
    model: :player_n | :player_1}

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
    
    port = Port.open({:spawn, "python3 #{medusa_py} #{medusa_model_1} #{medusa_model_n}"}, options)
    ref = Port.monitor(port)
    
    {port, ref}
  end

  @spec close(port :: port(), ref :: reference()) :: :ok
  def close(port, ref) do
    Port.demonitor(ref, :flush)
    Port.close(port)
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
	for [model, player, pred] <- Jason.decode!(data), do: %__MODULE__{player_id: player, inactive_in_future: pred, model: model}
    end
  end
end

defmodule MedusaPort do
  
  # this should be arguments or app enviroments, not module attributes
  @medusa_port_file "medusa_app.py"
  @medusa_model_file "medusa_model.pkl"
  @medusa_env_dir "medusa_env/lib/python3.7/site-packages"
  
  
  @doc """
  Launch the port wich will communicate with the prediction model. The codification is trought JSON.
  """
  @spec open_port(model_dir :: binary()) :: {port(), reference()}
  def open_port(model_dir) do
    file_port = model_dir <> "/" <> @medusa_port_file
    file_model = model_dir <> "/" <> @medusa_model_file
    python_path = model_dir <> "/" <> @medusa_env_dir
    
    env = [{'PYTHONPATH', String.to_charlist(python_path)}]
    
    options = [
      :binary,
      {:packet, 4},
      {:env, env}
    ]
    
    port = Port.open({:spawn, "python3 " <> file_port <> " " <> file_model}, options)
    ref = Port.monitor(port)
    
    {port, ref}
    
  end
  
  @doc """
  Load the prediction model `model_name` in the current python port. You shuld receive 
  `{port, {:data, "\"loaded\""}}` in case of a succesfull loading or `{port, {:data, "\"not loaded\""}}` in case
  of failure.
  """
  @spec load_model(port :: port()) :: true
  def load_model(port) do
    cmd = Jason.encode!(["load", ""])
    Port.command(port, cmd)
  end
  
  @spec send_players(any(), port :: port()) :: true
  def send_players(players, port) do
    cmd = Jason.encode!(["predict", players])
    Port.command(port, cmd)
  end
  
end
