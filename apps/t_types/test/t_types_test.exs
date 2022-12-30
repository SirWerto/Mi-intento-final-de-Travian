defmodule TTypesTest do
  use ExUnit.Case
  doctest TTypes

  test "Ensure tribes encoding/decoding is consistant" do
    assert(1 == decode_encode(1))
    assert(2 == decode_encode(2))
    assert(3 == decode_encode(3))
    assert(4 == decode_encode(4))
    assert(5 == decode_encode(5))
    assert(6 == decode_encode(6))
    assert(7 == decode_encode(7))
    assert(8 == decode_encode(8))
  end

  defp decode_encode(tribe_int), do: TTypes.encode_tribe(TTypes.decode_tribe(tribe_int))

  test "Encode or decode an unknown tribe fails" do
    assert_raise(CaseClauseError, fn -> TTypes.encode_tribe(:unknown_tribe) end)
    assert_raise(CaseClauseError, fn -> TTypes.decode_tribe(20) end)
  end

  test "From/to server_id path" do
    server_id = "https://ts4.x1.asia.travian.com"
    assert(server_id == TTypes.server_id_from_path(TTypes.server_id_to_path(server_id)))
  end

  test "Distance perform euclidean distance" do
    assert_in_delta(TTypes.distance401(4.0, 132.0, 0.0, 0.0), 132.1, 0.1)
    assert_in_delta(TTypes.distance401(4.0, 132.0, 6.0, 134.0), 2.8, 0.1)
    assert_in_delta(TTypes.distance401(4.0, 132.0, 4.0, 128.0), 4, 0.1)
  end

  test "Distance follows toroid behaviours" do
    assert_in_delta(TTypes.distance401(4.0, 132.0, -200.0, -200.0), 208.7, 0.1)
    assert_in_delta(TTypes.distance401(4.0, 132.0, 200.0, -200.0), 207.8, 0.1)
    assert_in_delta(TTypes.distance401(4.0, 132.0, 200.0, 200.0), 207.5, 0.1)
    assert_in_delta(TTypes.distance401(4.0, 132.0, -200.0, 199.0), 208.1, 0.1)
    assert_in_delta(TTypes.distance401(4.0, 132.0, 6.0, -144.0), 125, 0.1)
  end
end
