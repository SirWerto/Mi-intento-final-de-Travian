defmodule Medusa do
  @moduledoc """
  `Medusa` is the application which holds the pipeline for making predictions.
  """

  @type player_status :: :active, :inactive, :future_inactive


  @spec subscribe() :: :ok
  def subscribe(), do: :ok

  @spec unsubscribe() :: :ok
  def unsubscribe(), do: :ok

end
