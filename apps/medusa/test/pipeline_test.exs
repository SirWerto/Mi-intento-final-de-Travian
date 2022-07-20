defmodule Medusa.Pipeline.Test do
  use ExUnit.Case


  setup_all do
    sample = [
      %Medusa.Pipeline.Step1{
	player_id: "player_id",
	date: ~D[2022-01-02],
	total_population: 39,
	n_villages: 1,
	village_pop: %{"village_id" => 39},
	tribes_summary: %{romans: 1},
	center_mass_x: 1.0,
	center_mass_y: 2.0,
	distance_to_origin: 2.24},

      %Medusa.Pipeline.Step1{
	player_id: "player_id",
	date: ~D[2022-01-03],
	total_population: 39,
	n_villages: 1,
	village_pop: %{"village_id" => 39},
	tribes_summary: %{romans: 1},
	center_mass_x: 1.0,
	center_mass_y: 2.0,
	distance_to_origin: 2.24},

      %Medusa.Pipeline.Step1{
	player_id: "player_id",
	date: ~D[2022-01-04],
	total_population: 39,
	n_villages: 1,
	village_pop: %{"village_id" => 39},
	tribes_summary: %{romans: 1},
	center_mass_x: 1.0,
	center_mass_y: 2.0,
	distance_to_origin: 2.24}]


    %{sample: sample}
  end


  # test "Days must be consecutive and sorted, otherwise error", %{sample: [day_minus_two, day_minus_one, current_day]} do
  #   assert_raise(RuntimeError, fn -> Medusa.Pipeline.is_inactive(day_minus_one, day_minus_two, current_day) end)
  #   assert_raise(RuntimeError, fn -> Medusa.Pipeline.is_inactive(day_minus_two, day_minus_one, current_day |> Map.put(:date, ~D[2022-01-07])) end)
  # end


  test "Inactive ONLY if no positive increase in any of her/his village in 3 consecutive days and no new villages", %{sample: [day_minus_two, day_minus_one, current_day]} do

    assert(Medusa.Pipeline.is_inactive(day_minus_two, day_minus_one, current_day) == true)
  end

  test "If only no increase for one day, still active", %{sample: [day_minus_two, day_minus_one, current_day]} do
    day_minus_two_edited_1= day_minus_two |> Map.put(:village_pop, %{"village_id" => 39})
    day_minus_one_edited_1= day_minus_one |> Map.put(:village_pop, %{"village_id" => 40})
    current_day_edited_1 = current_day |> Map.put(:village_pop, %{"village_id" => 40})


    day_minus_two_edited_2= day_minus_two |> Map.put(:village_pop, %{"village_id" => 40})
    day_minus_one_edited_2= day_minus_one |> Map.put(:village_pop, %{"village_id" => 40})
    current_day_edited_2 = current_day |> Map.put(:village_pop, %{"village_id" => 50})

    assert(Medusa.Pipeline.is_inactive(day_minus_two_edited_1, day_minus_one_edited_1, current_day_edited_1) == false)
    assert(Medusa.Pipeline.is_inactive(day_minus_two_edited_2, day_minus_one_edited_2, current_day_edited_2) == false)
  end


  test "Inactive but village increase marked as active", %{sample: [day_minus_two, day_minus_one, current_day]} do
    current_day = current_day |> Map.put(:village_pop, %{"village_id" => 39, "village_2" => 30})

    assert(Medusa.Pipeline.is_inactive(day_minus_two, day_minus_one, current_day) == false)
  end

  defp gen_input_output_pipeline() do
    date = DateTime.now!("Etc/UTC") |> DateTime.to_date()
    case boolean() do
      true -> gen_fe1_input_output(date)
      false -> gen_fen_input_output(date)
    end
  end

  defp gen_fe1_input_output(date) do

    output = %Medusa.Pipeline.Step2{
      fe_type: :ndays_1,
      fe_struct: 
      %Medusa.Pipeline.FE1{
	player_id: bitstring(),
	date: date,
	inactive_in_current: :undefined,
	total_population: integer(1, :inf),
	n_villages: integer(1, :inf),
	tribes_summary: %{},
	center_mass_x: float(),
	center_mass_y: float(),
	distance_to_origin: float(0, :inf)}}

    input = 

  end

  defp gen_fen_input_output(date)






end
