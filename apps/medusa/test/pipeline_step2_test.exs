defmodule Medusa.Pipeline.Step2Test do
  use ExUnit.Case

  setup_all do
    sample = %Medusa.Pipeline.Step1{
      player_id: "player_id",
      date: ~D[2022-01-02],
      total_population: 39,
      n_villages: 1,
      village_pop: %{"village_id" => 39},
      tribes_summary: %{romans: 1},
      center_mass_x: 1.0,
      center_mass_y: 2.0,
      distance_to_origin: 2.24}

    today = Date.utc_today()

    %{sample: sample, today: today}
  end


  # test "remove_non_consecutive must return nil if there is no struct1 with date == today", %{sample: sample, today: today} do
  #   input = [
  #     Map.put(sample, :date, Date.add(today, -1)),
  #     Map.put(sample, :date, Date.add(today, -3)),
  #     Map.put(sample, :date, Date.add(today, -2))
  #   ]

  #   assert(Medusa.Pipeline.Step2.remove_non_consecutive(input) == nil)
  # end


  test "remove_non_consecutive returns a sorted output whith today's struct as first", %{sample: sample, today: today} do
    input = [
      Map.put(sample, :date, Date.add(today, -1)),
      Map.put(sample, :date, Date.add(today, 0)),
      Map.put(sample, :date, Date.add(today, -2))
    ]

    output = [
      Map.put(sample, :date, Date.add(today, 0)),
      Map.put(sample, :date, Date.add(today, -1)),
      Map.put(sample, :date, Date.add(today, -2))
    ]

    assert(Medusa.Pipeline.Step2.remove_non_consecutive(input) == output)
  end

  test "remove_non_consecutive returns only consecutive days since today", %{sample: sample, today: today} do
    input = [
      Map.put(sample, :date, Date.add(today, -1)),
      Map.put(sample, :date, Date.add(today, 0)),
      Map.put(sample, :date, Date.add(today, -2)),
      # There is no -3 struct
      Map.put(sample, :date, Date.add(today, -4)),
      Map.put(sample, :date, Date.add(today, -5)),
      Map.put(sample, :date, Date.add(today, -6))
    ]

    output = [
      Map.put(sample, :date, Date.add(today, 0)),
      Map.put(sample, :date, Date.add(today, -1)),
      Map.put(sample, :date, Date.add(today, -2))
    ]

    assert(Medusa.Pipeline.Step2.remove_non_consecutive(input) == output)
  end


  test "apply_FE returns nil if it receives nil" do
    assert(Medusa.Pipeline.Step2.apply_FE(nil) == nil)
  end


  test "apply_FE returns nil if it receives an empty list" do
    assert(Medusa.Pipeline.Step2.apply_FE([]) == nil)
  end


  test "if apply_FE receivies 1 struct, returns %Medusa.Pipeline.Step2{fe_type: :ndays_1}", %{sample: sample, today: today} do
    input = [
      Map.put(sample, :date, Date.add(today, 0))
    ]

    output = Medusa.Pipeline.Step2.apply_FE(input)
    assert(output.fe_type == :ndays_1)
  end


  test "if apply_FE receivies more than 1 struct, returns %Medusa.Pipeline.Step2{fe_type: :ndays_n}", %{sample: sample, today: today} do
    input = [
      Map.put(sample, :date, Date.add(today, 0)),
      Map.put(sample, :date, Date.add(today, -1))
    ]

    output = Medusa.Pipeline.Step2.apply_FE(input)
    assert(output.fe_type == :ndays_n)
  end


  test "if apply_FE receivies more than 5 structs, only take 5 days", %{sample: sample, today: today} do
    input = [
      Map.put(sample, :date, Date.add(today, 0)),
      Map.put(sample, :date, Date.add(today, -1)),
      Map.put(sample, :date, Date.add(today, -2)),
      Map.put(sample, :date, Date.add(today, -3)),
      Map.put(sample, :date, Date.add(today, -4)),
      Map.put(sample, :date, Date.add(today, -5))
    ]

    output = Medusa.Pipeline.Step2.apply_FE(input)
    assert(output.fe_type == :ndays_n)
    assert(output.fe_struct.n_days == 5)
  end
end
