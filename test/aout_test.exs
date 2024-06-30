defmodule AoutTest do
  use ExUnit.Case
  doctest Easm.ADotOut
  alias Easm.Lexer
  alias Easm.Symbol
  alias Easm.ADotOut

  test "aout create" do
    aout = ADotOut.new()
    assert aout.absolute_location == 0
    assert aout.relocatable_location == 0
  end

  test "symbols" do
    aout = ADotOut.new()
    name = "A"
    val = Symbol.symbol_here(aout)
    aout1 = ADotOut.handle_address_symbol(aout, name, val)
    assert aout1.symbols |> Map.get("A") == val
    aout2 = ADotOut.handle_address_symbol(aout, name, val)
    assert aout1.symbols == aout2.symbols
    aout3 = ADotOut.handle_address_symbol(aout, "", val)
    assert aout3.symbols == aout.symbols
    aout4 = ADotOut.handle_address_symbol(aout, name, nil)
    assert aout4.symbols == aout.symbols
  end
end
