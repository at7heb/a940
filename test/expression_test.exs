defmodule ExpressionTest do
  use ExUnit.Case
  doctest Easm.Expression
  # alias Easm.Lexer
  # alias Easm.Symbol
  # alias Easm.ADotOut
  alias Easm.Expression

  test "expression operator priorities" do
    a = Expression.priority({:operator, "+"})
    b = Expression.priority({:operator, "-"})
    assert a == b
    c = Expression.priority({:operator, "*"})

    assert a != c

    d = Expression.priority({:operator, "U+"})
    e = Expression.priority({:operator, "U-"})

    assert d == e
  end
end
