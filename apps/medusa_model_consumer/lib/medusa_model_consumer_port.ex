defmodule MedusaModelConsumerPort do

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
  
end
