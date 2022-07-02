defmodule Medusa.Pipeline.TrainIntegration.Test do
  use ExUnit.Case


  ##### It shuld be done with property testing


  test "get_train_data split&process the input data in different samples for the models and assigns an status to them" do
    _input = [
      {~D[2022-01-02], [%{
			   grid_position: 1,
			   x: 1,
			   y: 2,
			   tribe: 1,
			   village_id: "village_id",
			   village_name: "village_name",
			   player_id: "player_id",
			   player_name: "player_name",
			   alliance_id: "alliance_id",
			   alliance_name: "alliance_name",
			   population: 39
			}]},
      {~D[2022-01-03], [%{
			   grid_position: 1,
			   x: 1,
			   y: 2,
			   tribe: 1,
			   village_id: "village_id",
			   village_name: "village_name",
			   player_id: "player_id",
			   player_name: "player_name",
			   alliance_id: "alliance_id",
			   alliance_name: "alliance_name",
			   population: 45
			}]},
      {~D[2022-01-04], [%{
			   grid_position: 1,
			   x: 1,
			   y: 2,
			   tribe: 1,
			   village_id: "village_id",
			   village_name: "village_name",
			   player_id: "player_id",
			   player_name: "player_name",
			   alliance_id: "alliance_id",
			   alliance_name: "alliance_name",
			   population: 46
			}]},

      {~D[2022-01-05], [%{
			   grid_position: 1,
			   x: 1,
			   y: 2,
			   tribe: 1,
			   village_id: "village_id",
			   village_name: "village_name",
			   player_id: "player_id",
			   player_name: "player_name",
			   alliance_id: "alliance_id",
			   alliance_name: "alliance_name",
			   population: 47
			}]},
      {~D[2022-01-06], [%{
			   grid_position: 1,
			   x: 1,
			   y: 2,
			   tribe: 1,
			   village_id: "village_id",
			   village_name: "village_name",
			   player_id: "player_id",
			   player_name: "player_name",
			   alliance_id: "alliance_id",
			   alliance_name: "alliance_name",
			   population: 57
			}]}]


  end
end
