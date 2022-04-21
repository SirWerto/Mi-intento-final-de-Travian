defmodule CollectorTest do
  use ExUnit.Case
  doctest Collector

  @moduletag :capture_log


  test "ignore pid down monitors if there aren't in active_process" do
    {:ok, pid} = start_supervised({UUT, [0]})

    input_state = %Collector.GenCollector{tref: nil, active_p: %{self() => "some ref"}}
    
    assert({:noreply, input_state} == Collector.GenCollector.handle_info({:DOWN, "some ref", :process, pid, :normal}, input_state))
    assert({:noreply, input_state} == Collector.GenCollector.handle_info({:DOWN, "some ref", :process, pid, :shutdown}, input_state))
  end


  test "remove pid from active proccess if a down signal is received with reason :normal" do
    {:ok, pid} = start_supervised({UUT, [0]})
    ref = Process.monitor(pid)
    value = {ref, "https://ts4.x1.europe.travian.com", 0, :info}
    input_state = %Collector.GenCollector{tref: nil, active_p: %{pid => value}}
    
    {:noreply, output_state} = Collector.GenCollector.handle_info({:DOWN, ref, :process, pid, :normal}, input_state)
    assert(output_state.active_p == %{})
  end


  test "relaunch task if a down signal is received with reason no normal" do
    {:ok, pid} = start_supervised({UUT, [0]})
    ref = Process.monitor(pid)
    server_id = "https://ts4.x1.europe.travian.com"
    type = :info
    value = {ref, server_id, 0, type}
    input_state = %Collector.GenCollector{tref: nil, active_p: %{pid => value}}
    
    {:noreply, output_state} = Collector.GenCollector.handle_info({:DOWN, ref, :process, pid, :test_shutdown}, input_state)
    [{new_pid, {new_ref, server_id2, 1, type2}}] = Map.to_list(output_state.active_p)
    Process.exit(new_pid, :shutdown)
    assert(pid != new_pid)
    assert(ref != new_ref)
    assert(server_id == server_id2)
    assert(type == type2)
  end


  test "no relaunch task if the task has reached 3 tries" do
    {:ok, pid} = start_supervised({UUT, [0]})
    ref = Process.monitor(pid)
    server_id = "https://ts4.x1.europe.travian.com"
    type = :info
    value = {ref, server_id, 3, type}
    input_state = %Collector.GenCollector{tref: nil, active_p: %{pid => value}}
    
    {:noreply, output_state} = Collector.GenCollector.handle_info({:DOWN, ref, :process, pid, :test_shutdown}, input_state)
    assert(output_state.active_p == %{})
  end


  test "subscribe add a process to the state and monitors it" do
    {:ok, pid} = start_supervised({UUT, [0]})
    input_state = %Collector.GenCollector{tref: nil, active_p: %{}, subscriptions: %{}}

    {:reply, :subscribed, output_state} = Collector.GenCollector.handle_call(:subscribe, {pid, "some tag"}, input_state)
    assert(Map.has_key?(output_state.subscriptions, pid))
    assert(Map.fetch!(output_state.subscriptions, pid) |> is_reference())
  end


  test "if a process is already subscribed don't resuscribe it" do
    {:ok, pid} = start_supervised({UUT, [0]})
    ref = Process.monitor(pid)
    subscriptions = %{pid => ref}
    input_state = %Collector.GenCollector{tref: nil, active_p: %{}, subscriptions: subscriptions}


    {:reply, :subscribed, output_state} = Collector.GenCollector.handle_call(:subscribe, {pid, "some tag"}, input_state)
    assert(output_state.subscriptions == subscriptions)
  end


  test "if suscribed and a server is collected successful, send {:collected, type, server_id} and removes worker from state" do
    {:ok, pid} = start_supervised({UUT, [0]})
    ref = Process.monitor(pid)
    server_id = "https://ts4.x1.europe.travian.com"
    type = :snapshot
    value = {ref, server_id, 0, type}
    input_state = %Collector.GenCollector{tref: nil, active_p: %{pid => value}, subscriptions: %{self() => "some ref"}}

    {:noreply, output_state} = Collector.GenCollector.handle_cast({:collected, :snapshot, server_id, pid}, input_state)

    assert(output_state.active_p == %{})
    refute(Process.demonitor(ref, [:info]))

    assert_receive({:collected, :snapshot, ^server_id}, 500)
  end


  test "unsubscribe removes a process and demonitors it" do
    {:ok, pid} = start_supervised({UUT, [0]})
    ref = Process.monitor(pid)
    input_state = %Collector.GenCollector{tref: nil, active_p: %{}, subscriptions: %{pid => ref}}

    {:reply, :unsubscribed, output_state} = Collector.GenCollector.handle_call(:unsubscribe, {pid, "some tag"}, input_state)
    refute(Map.has_key?(output_state.subscriptions, pid))
    refute(Process.demonitor(ref, [:info]))
  end


  test "unsubscribe without being suscribed replies :unsuscribed" do
    {:ok, pid} = start_supervised({UUT, [0]})
    input_state = %Collector.GenCollector{tref: nil, active_p: %{}, subscriptions: %{}}
    {:reply, :unsubscribed, output_state} = Collector.GenCollector.handle_call(:unsubscribe, {pid, "some tag"}, input_state)
    refute(Map.has_key?(output_state.subscriptions, pid))
  end
end



defmodule UUT do
  use Agent

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def value do
    Agent.get(__MODULE__, & &1)
  end

  def increment do
    Agent.update(__MODULE__, &(&1 + 1))
  end

end
