defmodule Medusa do
  @moduledoc """
  `Medusa` is the application which holds the pipeline for making predictions.
  """

  @type player_status :: :active, :inactive, :future_inactive


  @spec subscribe() :: :ok
  def subscribe(), do: :ok

  @spec unsubscribe() :: :ok
  def unsubscribe(), do: :ok

  @spec etl(root_folder :: binary(), port :: pid(), server_id :: TTypes.server_id(), target_date :: Date.t()) :: :ok | {:error, any()}
  def etl(root_folder, port, server_id, target_date \\ Date.utc_today()) when is_binary(root_folder) and is_pid(port) and is_binary(server_id) do
    Medusa.ETL.apply(root_folder, port, server_id, target_date)
  end
  

end
