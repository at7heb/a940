defmodule ExpressionTest do
  use ExUnit.Case
  doctest Easm.Expression
  # alias Easm.Lexer
  alias Easm.Symbol
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
    token_list = tokens("100)")
    state = Expression.new(token_list, %{}, {8, 1})
    Expression.eval(state)

    # more complicated
    token_list = tokens("100+3)")
    state = Expression.new(token_list, %{}, {8, 1})
    Expression.eval(state)
    {result_val, result_rel} = Expression.eval(state)
    assert result_val == 67 and result_rel == 0

    # more complicated
    token_list = tokens("100+3-5-2)")
    state = Expression.new(token_list, %{}, {8, 1})
    Expression.eval(state)
    {result_val, result_rel} = Expression.eval(state)
    assert result_val == 60 and result_rel == 0

    # more complicated
    token_list = tokens("100+3-(5-2))")
    state = Expression.new(token_list, %{}, {8, 1})
    Expression.eval(state)
    {result_val, result_rel} = Expression.eval(state)
    assert result_val == 64 and result_rel == 0

    # divide
    token_list = tokens("100/2)")
    state = Expression.new(token_list, %{}, {8, 1})
    Expression.eval(state)
    {result_val, result_rel} = Expression.eval(state)
    assert result_val == 32 and result_rel == 0

    token_list = tokens("100+3)")
    state = Expression.new(token_list, %{}, {8, 1})
    Expression.eval(state)
    {result_val, result_rel} = Expression.eval(state)
    assert result_val == 67 and result_rel == 0

    token_list = tokens("100+3)")
    state = Expression.new(token_list, %{}, {8, 1})
    Expression.eval(state)
    {result_val, result_rel} = Expression.eval(state)
    assert result_val == 67 and result_rel == 0

    # multiply
    token_list = tokens("100*3)")
    state = Expression.new(token_list, %{}, {8, 1})
    val1 = Expression.eval(state)
    val2 = Expression.eval(state)
    {result_val, result_rel} = val2
    assert val1 == val2
    assert result_val == 192 and result_rel == 0
  end

  test "expressions like * + 1" do
    token_list = tokens("*+1)")
    state = Expression.new(token_list, %{}, {8, 1})
    val2 = Expression.eval(state)
    {result_val, result_rel} = val2
    assert result_val == 9 and result_rel == 1

    token_list = tokens("*-*)")
    state = Expression.new(token_list, %{}, {8, 1})
    val2 = Expression.eval(state)
    {result_val, result_rel} = val2
    assert result_val == 0 and result_rel == 0
  end

  test "operator evaluation" do
    value_stack = [{10, 0}, {5, 0}]
    new_stack = Expression.eval_negate(value_stack)
    assert length(new_stack) == 2
    assert {-10, 0} == hd(new_stack)

    new_stack = Expression.eval_binary(&Kernel.*/2, value_stack)
    assert length(new_stack) == 1
    assert {50, 0} == hd(new_stack)
    new_stack = Expression.eval_binary(&Kernel.div/2, value_stack)
    assert length(new_stack) == 1
    assert {0, 0} == hd(new_stack)
    new_stack = Expression.eval_binary(&Kernel.+/2, value_stack)
    assert length(new_stack) == 1
    assert {15, 0} == hd(new_stack)
    new_stack = Expression.eval_binary(&Kernel.-/2, value_stack)
    assert length(new_stack) == 1
    assert {-5, 0} == hd(new_stack)
  end

  test "expression with absolute symbol" do
    symbol_table = make_symbol_table()
    token_list = tokens("A2)")
    state = Expression.new(token_list, symbol_table, {8, 1})
    val2 = Expression.eval(state)
    {result_val, result_rel} = val2
    assert result_val == 19
    assert result_rel == 0
    token_list = tokens("R8-7)")
    state = Expression.new(token_list, symbol_table, {8, 1})
    val2 = Expression.eval(state)
    {result_val, result_rel} = val2
    assert result_val == 8 * 8 + 4 - 7
    assert result_rel == 1
    token_list = tokens("R7-R5)")
    state = Expression.new(token_list, symbol_table, {8, 1})
    val2 = Expression.eval(state)
    {result_val, result_rel} = val2
    assert result_val == 16
    assert result_rel == 0
    token_list = tokens("R7-*)")
    state = Expression.new(token_list, symbol_table, {8, 1})
    val2 = Expression.eval(state)
    {result_val, result_rel} = val2
    assert result_val == 52
    assert result_rel == 0
  end

  # test "undefined symbols" do
  #   symbol_table = make_symbol_table()
  #   token_list = tokens("U2)") |> dbg()
  #   state = Expression.new(token_list, symbol_table, {8, 1})
  #   val2 = Expression.eval(state) |> dbg
  #   {result_val, result_rel} = val2
  #   assert result_val == 19
  #   assert result_rel == 0
  # end

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

  def octal_number_token(expression), do: octal_number_token(expression, 0)

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

  def make_symbol_table() do
    Enum.reduce(0..9, %{}, fn num, symbols ->
      Map.put(symbols, "A" <> Integer.to_string(num), Symbol.symbol_absolute(0o10 * num + 3))
      |> Map.put(
        "R" <> Integer.to_string(num),
        Symbol.symbol_relative(0o10 * num + 4)
      )
      |> Map.put("U" <> Integer.to_string(num), Symbol.symbol_external())
    end)
  end
end
