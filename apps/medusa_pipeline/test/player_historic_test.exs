defmodule MedusaPropTestPlayerHistoric do
  use ExUnit.Case
  doctest MedusaPipeline.PlayerHistoric
  use PropCheck, default_opts: [numtests: 1000]

  ###############
  ### Helpers ### 
  ###############

  ##################
  ### Generators ### 
  ##################
  def fixed_int_list(0) do
    []
  end

  def fixed_int_list(any_size) do
    let n <- resize(any_size, non_empty(list(pos_integer()))) do
      n
    end
  end

  def create_pops() do
    let [
      n_village <- pos_integer(),
      n_active_village <- integer(0, ^n_village),
      populations <- fixed_int_list(^n_village),
      increase <- fixed_int_list(^n_active_village),
      decrease <- fixed_int_list(^n_village - ^n_active_village)
    ] do
      population_increase = Enum.sum(increase)
      population_decrease = -1 * Enum.sum(decrease)

      case decrease == [] do
        true ->
          {Enum.sum(populations), n_village, n_active_village, population_increase, 0,
           populations, increase}

        false ->
          IO.inspect({populations})

          populations =
            Enum.zip_reduce([populations, decrease], [], fn [pop, dec], acc ->
              [pop + dec | acc]
            end)

          decrease = Enum.map(decrease, fn x -> -1 * x end)
          pop_diff = decrease ++ increase

          {Enum.sum(populations), n_village, n_active_village, population_increase,
           population_decrease, populations, pop_diff}
      end
    end
  end

  def random_result() do
    let [
      player_id <- bitstring(),
      {population_total, n_village, n_active_village, population_increase, population_decrease,
       populations, pop_diff} <- create_pops()
      # date_diffs <- fixed_int_list(^n_village)
    ] do
      n_races = 1
      date = ~D[2019-09-05]
      races = for _n <- 0..(n_village - 1), do: 1
      date_diffs = for _n <- 0..(n_village - 1), do: 1

      villages =
        [races, populations, pop_diff, date_diffs]
        |> Enum.zip_reduce([], fn elems, acc -> [List.to_tuple(elems) | acc] end)

      input = {{player_id, date}, villages}

      output =
        {player_id, date, hd(date_diffs), n_village, n_active_village, population_total,
         population_increase, population_decrease, n_races}

      {input, output}
    end
  end

  ##################
  ### Properties ### 
  ##################

  # property "player_id and date don't change over the pipeline" do
  #   forall {input, output} <- random_result() do
  #   player_id = elem(output, 0)
  #   date = elem(output, 1)
  #   result = MedusaPipeline.PlayerHistoric.create_player_attrs(input)
  #   assert(player_id === elem(result,0), "player_id has changed")
  #   assert(date === elem(result,1), "player_id has changed")
  #   end
  # end

  # property "n_active_village <= n_village" do
  #   forall {input, output} <- random_result() do
  #   n_village = elem(output, 3)
  #   n_active_village = elem(output, 4)
  #   result = MedusaPipeline.PlayerHistoric.create_player_attrs(input)
  #   res_n_village = elem(result, 3)
  #   res_n_active_village = elem(result, 4)

  #   IO.puts("hola")
  #   IO.inspect(input)
  #   IO.inspect({n_village, n_active_village})
  #   IO.puts("hola fin")
  #   assert(n_village === res_n_village, "n_village bad computed")
  #   assert(n_active_village === res_n_active_village, "n_active_village bad computed")
  #   assert(res_n_village >= res_n_active_village, "n_active_village bigger then n_village")
  #   end
  # end
end
