
defmodule Collector.CollectorSupervisor do
  @moduledoc false
  use DynamicSupervisor

  def start_link(_init_arg) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_worker_info(server_id :: TTypes.server_id()) :: {:ok, {pid(), reference()}} | {:error, any()}
  def start_worker_info(server_id) do
    case DynamicSupervisor.start_child(__MODULE__, {Collector.GenWorker, [server_id, :info]}) do
      {:ok, pid} ->
	ref = Process.monitor(pid)
	{:ok, {pid, ref, server_id, :info}}
      :ignore -> {:error, {server_id, :info, :ignore}}
      {:error, reason} -> {:error, {server_id, :info, reason}}
    end
  end


  @spec start_worker_snapshot(server_id :: TTypes.server_id()) :: {:ok, {pid(), reference()}} | {:error, any()}
  def start_worker_snapshot(server_id) do
    case DynamicSupervisor.start_child(__MODULE__, {Collector.GenWorker, [server_id, :snapshot]}) do
      {:ok, pid} ->
	ref = Process.monitor(pid)
	{:ok, {pid, ref, server_id, :snapshot}}
      :ignore -> {:error, {server_id, :snapshot, :ignore}}
      {:error, reason} -> {:error, {server_id, :snapshot, reason}}
    end
  end
end
