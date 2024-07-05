defmodule ExpressionTest do
  use ExUnit.Case
  doctest Easm.Expression
  # alias Easm.Lexer
  # alias Easm.Symbol
  # alias Easm.ADotOut
  alias Easm.Expression

  test "expression operator priorities" do
    a = Expression.priority(op(:add))
    b = Expression.priority(op(:subtract))
    assert a == b
    c = Expression.priority(op(:multiply))

    assert a != c

    d = Expression.priority(op(:unary_plus))
    e = Expression.priority(op(:unary_minus))

    assert d == e
    # results: :first_lower, :equal, :first_higher
    assert :first_lower == Expression.compare_priorities(op(:add), op(:multiply))
    assert :equal == Expression.compare_priorities(op(:add), op(:add))
    assert :first_higher == Expression.compare_priorities(op(:multiply), op(:add))
  end

  test "handle one token" do
    # result will be operator push
    # result will be value push
    # result will be eval
  end

  def op(:add), do: {:operator, "+"}
  def op(:subtract), do: {:operator, "-"}
  def op(:multiply), do: {:operator, "*"}
  def op(:divide), do: {:operator, "/"}
  def op(:unary_plus), do: {:operator, "U+"}
  def op(:unary_minus), do: {:operator, "U-"}

  def token(:value, n),
    do: {:value, n}

  def tokens(expression) when is_binary(string), do: tokens(expression, [])

  def tokens("", token_list), do: Enum.rev(token_list)

  def tokens()
end
