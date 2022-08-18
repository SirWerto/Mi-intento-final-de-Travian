defmodule Collector.Supervisor.Snapshot do
  @moduledoc false
  use DynamicSupervisor
  require Logger

  @spec start_link(any()) :: Supervisor.on_start()
  def start_link(_init_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_child(server_id :: TTypes.server_id()) ::
          {:ok, {pid(), reference()}} | {:error, any()}
  def start_child(server_id) do
    max_tries = Application.get_env(:collector, :max_tries, 3)

    child_spec = %{
      id: "Collector.GenWorker.Snapshot",
      start: {Collector.GenWorker.Snapshot, :start_link, [server_id, max_tries]},
      restart: :transient
    }

    case DynamicSupervisor.start_child(__MODULE__, child_spec) do
      {:ok, pid} ->
        ref = Process.monitor(pid)
        {:ok, {pid, ref}}

      :ignore ->
        Logger.info(%{
          msg: "Unable to launch GenWorker.Snapshot",
          reason: :ignore,
          type_collection: :snapshot,
          server_id: server_id
        })

        {:error, {server_id, :ignore}}

      {:error, reason} ->
        Logger.info(%{
          msg: "Unable to launch GenWorker.Snapshot",
          reason: :ignore,
          type_collection: :snapshot,
          server_id: server_id
        })

        {:error, {server_id, reason}}
    end
  end
end
