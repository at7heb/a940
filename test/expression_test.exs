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
    true
  end

  test "tokens from string" do
    {token, expression} = octal_number_token("100+A1")
    assert token == {:number, "100B"}
    assert expression == "+A1"

    token_list = tokens("100+A1")
    assert Enum.at(token_list, 0) == {:number, "100B"}
    assert tokens("100+3*(5-2))") |> Enum.at(3) == {:asterisk, "*"}
  end

  test "expression eval" do
    token_list = tokens("100)") |> dbg
    state = Expression.new(token_list, %{}, {8, 1}) |> dbg
    Expression.eval(state) |> dbg
  end

  def op(:add), do: {:operator, "+"}
  def op(:subtract), do: {:operator, "-"}
  def op(:multiply), do: {:operator, "*"}
  def op(:divide), do: {:operator, "/"}
  def op(:unary_plus), do: {:operator, "U+"}
  def op(:unary_minus), do: {:operator, "U-"}

  def token(:value, n),
    do: {:value, n}

  def tokens(expression) when is_binary(expression),
    do: tokens(String.replace(expression, " ", "") |> String.upcase(), [])

  def tokens("", token_list), do: Enum.reverse(token_list)

  def tokens(expression, token_list) do
    {token, new_expression} =
      cond do
        String.starts_with?(expression, "A") ->
          symbol_token(expression)

        String.starts_with?(expression, "R") ->
          symbol_token(expression)

        String.starts_with?(expression, "U") ->
          symbol_token(expression)

        String.starts_with?(expression, "*") ->
          {{:asterisk, "*"}, String.slice(expression, 1..-1//1)}

        String.starts_with?(expression, "/") ->
          {{:operator, "/"}, String.slice(expression, 1..-1//1)}

        String.starts_with?(expression, "+") ->
          {{:operator, "+"}, String.slice(expression, 1..-1//1)}

        String.starts_with?(expression, "-") ->
          {{:operator, "-"}, String.slice(expression, 1..-1//1)}

        String.starts_with?(expression, "(") ->
          {{:open_paren, "("}, String.slice(expression, 1..-1//1)}

        String.starts_with?(expression, ")") ->
          {{:close_paren, ")"}, String.slice(expression, 1..-1//1)}

        String.starts_with?(expression, ["0", "1", "2", "3", "4", "5", "6", "7"]) ->
          octal_number_token(expression)
      end

    tokens(new_expression, [token | token_list])
  end

  def symbol_token(expression) when is_binary(expression) do
    token = {:symbol, String.slice(expression, 0, 2)}
    new_expression = String.slice(expression, 2..-1//1)
    {token, new_expression}
  end

  def octal_number_token(expression), do: octal_number_token(expression, 1)

  def octal_number_token(expression, length) do
    cond do
      String.slice(expression, length, 1)
      |> String.starts_with?(["0", "1", "2", "3", "4", "5", "6", "7"]) ->
        octal_number_token(expression, length + 1)

      true ->
        {{:number, String.slice(expression, 0, length) <> "B"},
         String.slice(expression, length..-1//1)}
    end
  end
end
