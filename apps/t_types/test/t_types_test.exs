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

end
