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
end
