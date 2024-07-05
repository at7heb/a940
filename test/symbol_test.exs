defmodule SymbolTest do
  use ExUnit.Case
  doctest Easm.Symbol
  alias Easm.ADotOut
  # alias Easm.Lexer
  alias Easm.Symbol

  test "create addresses" do
    addr = Symbol.new()
    assert addr.state == :unknown
    assert addr.value == nil
    assert addr.definition == []
    addr = Symbol.new(0o55)
    assert addr.value == 45
    addr = Symbol.new(42, [:abc], :known)
    assert addr.value == 42
    assert addr.definition == [:abc]
    assert addr.state == :known
  end

  test "symbol_relative" do
    aout = ADotOut.new() |> ADotOut.increment_current_location()
    sym1 = Symbol.symbol_relative(aout, 1, 5, [:token])
    assert sym1.value == 6
    sym2 = Symbol.symbol_relative(aout, -1, 1, [:ok])
    assert sym2.value == 0
  end
end
