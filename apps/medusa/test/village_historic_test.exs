defmodule MedusaPropTestPipeBase do
  use ExUnit.Case
  use PropCheck, default_opts: [numtests: 1000]


###############
### Helpers ### 
###############

  def make_village_logs(init_date, init_pop, race, date_increments, pop_increments) do
    date_increments = [0 | date_increments]
    pop_increments = [0 | pop_increments]
    dates = Enum.scan(date_increments, init_date, fn inc, acc -> Date.add(acc, inc) end)
    pops = Enum.scan(pop_increments, init_pop, &(&1 + &2))
    races = repeat(length(pops), race)
    Enum.zip_reduce([dates, races, pops], [], fn elements, acc -> [List.to_tuple(elements) | acc] end)
  end
  
  def ones(mimic) when is_list(mimic) do
    len = length(mimic)
    for _x <- 0..len-1, do: 1
  end
  
  def repeat(len, elem) do
    for _x <- 0..len-1, do: elem
  end
  
  def pick_first(results, index) do
    head = hd(results)
    elem(head, index)
  end

##################
### Generators ### 
##################
  
  def random_race() do
    let [race <- integer(0,5)] do
      race
    end
  end
  
  def increments_random() do
    let [inc1 <- non_empty(list(pos_integer())) , inc2 <- non_empty(list(pos_integer()))] do
      case length(inc1) > length(inc2) do
	true -> {Enum.slice(inc1, 0, length(inc2)), inc2}
	false -> {inc1, Enum.slice(inc2, 0, length(inc1))}
      end
    end
  end
  
  def increments_consecutives() do
    let [inc2 <- non_empty(list(pos_integer()))] do
      date_increments = for _x <- 0..length(inc2)-1, do: 1
      {date_increments, inc2}
    end
  end
  
  def info_consecutive() do
    let [player_id <- bitstring(),
	 village_id <- bitstring(),
	 race <- random_race(),
	 start_population <- pos_integer(),
	 {date_increments, pop_increments} <- increments_consecutives()] do
      
      start_date = ~D[2019-09-05]
      village_logs = make_village_logs(start_date, start_population, race, date_increments, pop_increments)
      {player_id, village_id, race, start_population, pop_increments, start_date, date_increments, village_logs}
    end
  end
  
  
  def info_random() do
    let [player_id <- bitstring(),
	 village_id <- bitstring(),
	 race <- random_race(),
	 start_population <- pos_integer(),
	 {date_increments, pop_increments} <- increments_random()] do
      
      start_date = ~D[2019-09-05]
      village_logs = make_village_logs(start_date, start_population, race, date_increments, pop_increments)
      {player_id, village_id, race, start_population, pop_increments, start_date, date_increments, village_logs}
    end
  end

##################
### Properties ### 
##################
# {player_id, village_id, race, start_population, pop_increments, start_date, date_increments, village_logs}

property "create_village_attr maintains player_id and village_id" do
    forall info <- info_random() do

      player_id = elem(info, 0)
      village_id = elem(info, 1)
      village_logs = elem(info, 7)


      {{player_id_2, village_id_2}, _results} = Medusa.VillageHistoric.create_village_attrs({{player_id, village_id}, village_logs})

      assert(player_id === player_id_2, "player_id changes over the pipeline")
      assert(village_id === village_id_2, "village_id changes over the pipeline")
      end
end

property "create_village_attr race don't change over the pipeline" do
    forall info <- info_random() do
      player_id = elem(info, 0)
      village_id = elem(info, 1)
      village_logs = elem(info, 7)
      race = elem(info, 2)

      {{_player_id, _village_id}, results} = Medusa.VillageHistoric.create_village_attrs({{player_id, village_id}, village_logs})

      assert(Enum.all?(results, fn x -> elem(x, 1) === race end), "race changes over the pipeline")
      end
end

property "create_village_attr date_diff === 1 when consecutive days" do
    forall info <- info_consecutive() do
      player_id = elem(info, 0)
      village_id = elem(info, 1)
      village_logs = elem(info, 7)

      {{_player_id, _village_id}, results} = Medusa.VillageHistoric.create_village_attrs({{player_id, village_id}, village_logs})
      assert(Enum.all?(results, fn x -> elem(x, 4) === 1 end), "date diff != 1 when consecutive days")
      end
end

property "length(village_logs) = length(output) + 1 due to compute the growth" do
    forall info <- info_random() do
      player_id = elem(info, 0)
      village_id = elem(info, 1)
      village_logs = elem(info, 7)
      pop_increments = elem(info, 4)

      {{_player_id, _village_id}, results} = Medusa.VillageHistoric.create_village_attrs({{player_id, village_id}, village_logs})

      assert(length(village_logs) - length(results) === 1, "growth computation is not working")
      assert(length(results) === length(pop_increments), "growth computation is not working")
      end
end


property "first population is start_population" do
    forall info <- info_random() do
      player_id = elem(info, 0)
      village_id = elem(info, 1)
      village_logs = elem(info, 7)
      start_population = elem(info, 3)

      {{_player_id, _village_id}, results} = Medusa.VillageHistoric.create_village_attrs({{player_id, village_id}, village_logs})

      case length(village_logs) >= 2 do
	true -> assert(pick_first(results, 2) === start_population, "bad starting population")
	false -> true
	end
      end
end

property "first date is start_date" do
    forall info <- info_random() do
      player_id = elem(info, 0)
      village_id = elem(info, 1)
      village_logs = elem(info, 7)
      start_date = elem(info, 5)

      {{_player_id, _village_id}, results} = Medusa.VillageHistoric.create_village_attrs({{player_id, village_id}, village_logs})

      case length(village_logs) >= 2 do
	true -> assert(pick_first(results, 0) === start_date, "bad starting date")
	false -> true
	end
      end
end

property "pop diff computation test" do
    forall info <- info_random() do
      player_id = elem(info, 0)
      village_id = elem(info, 1)
      village_logs = elem(info, 7)
      pop_increments = elem(info, 4)

      {{_player_id, _village_id}, results} = Medusa.VillageHistoric.create_village_attrs({{player_id, village_id}, village_logs})

      bool = Enum.map(results, fn x -> elem(x,3) end)
      |> Enum.zip(pop_increments)
      |> Enum.map(fn {inc1, inc2} -> inc1 === inc2 end)
      |> Enum.all?()
      assert(bool, "pop diff are not equal")
      end
end

property "date diff computation test" do
    forall info <- info_random() do
      player_id = elem(info, 0)
      village_id = elem(info, 1)
      village_logs = elem(info, 7)
      date_increments = elem(info, 6)

      {{_player_id, _village_id}, results} = Medusa.VillageHistoric.create_village_attrs({{player_id, village_id}, village_logs})

      bool = Enum.map(results, fn x -> elem(x,4) end)
      |> Enum.zip(date_increments)
      |> Enum.map(fn {inc1, inc2} -> inc1 === inc2 end)
      |> Enum.all?()
      assert(bool, "pop diff are not equal")
      end
end
end
