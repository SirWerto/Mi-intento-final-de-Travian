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

  test "subscribe to Medusa.Brain" do
    assert Medusa.Brain.subscribe(self()) == {:ok, :subscribed}
    assert Medusa.Brain.subscribers() == [self()]
  end

  test "send players to medusa" do
    players_id = ["player1", "player2"]
    assert Medusa.eval_players(players_id) == :ok
    evaluated_players = Medusa.evaluated_players()
    assert has_keys?(evaluated_players, players_id)
  end


### SetUp
### Private Functions
  defp has_keys?(some_map, keys) do
    MapSet.subset?(MapSet.new(keys), MapSet.new(Map.keys(some_map)))
  end
end
