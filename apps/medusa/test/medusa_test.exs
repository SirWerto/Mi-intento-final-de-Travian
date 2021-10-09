defmodule MedusaTest do
  use ExUnit.Case
  doctest Medusa

  test "start Medusa.Brain" do
    {:error, {:already_started, brain}} = Medusa.Brain.start_link()
    assert Process.whereis(Medusa.Brain) == brain
  end

   test "Medusa.Brain is alive" do
     brain = Process.whereis(Medusa.Brain)
     assert brain != nil
     assert Supervisor.which_children(Medusa.Supervisor) == [{"brain", brain, :worker, [Medusa.Brain]}]
   end

  test "subscribe to Medusa" do
    assert Medusa.subscribe(self()) == {:ok, :subscribed}
    assert Medusa.subscribers() == [self()]
  end
  
  test "subscribe multiple times don't affect Medusa" do
    assert Medusa.subscribe(self()) == {:ok, :subscribed}
    assert Medusa.subscribe(self()) == {:ok, :subscribed}
    assert Medusa.subscribers() == [self()]
  end

  test "subscribe to Medusa.Brain" do
    assert Medusa.Brain.subscribe(self()) == {:ok, :subscribed}
    assert Medusa.Brain.subscribers() == [self()]
  end

  test "unsubscribe to Medusa" do
    assert Medusa.subscribe(self()) == {:ok, :subscribed}
    assert Medusa.unsubscribe(self()) == {:ok, :unsubscribed}
    assert Medusa.subscribers() == []
  end

  test "unsubscribe to Medusa.Brain" do
    assert Medusa.Brain.subscribe(self()) == {:ok, :subscribed}
    assert Medusa.Brain.unsubscribe(self()) == {:ok, :unsubscribed}
    assert Medusa.Brain.subscribers() == []
  end

  test "Unsubscribe without being subscribed" do
    assert Medusa.Brain.unsubscribe(self()) == {:ok, :unsubscribed}
  end

  test "send players to medusa" do
    players_id = ["player1", "player2"]
    assert Medusa.send_players(players_id) == :ok
  end


### SetUp
### Private Functions
end
