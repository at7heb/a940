defmodule Easm.Expression do
  alias Easm.Expression
  # alias Easm.Symbol

  defstruct operation_stack: [], value_stack: [], expect: [], tokens: [], star: {0, 0}

  @moduledoc """
  evaluate address expressions, keeping track of the resulting relocation factor
  """

  def new(tokens, symbols, star) do
    tokens |> dbg

    new_tokens =
      Enum.map(tokens, fn {type, text} ->
        convert_token({type, text}, symbols)
      end)

    new_tokens |> dbg

    %Expression{
      operation_stack: [{:open_paren, "("}],
      value_stack: [],
      expect: [:symbol, :number, :open_paren, :unary],
      tokens: new_tokens,
      star: star
    }
  end

  def start_eval(tokens, {value, relocation} = star, symbols)
      when is_list(tokens) and is_integer(value) and is_integer(relocation) and is_map(symbols) do
    state = new(tokens ++ [{:close_paren, ")"}], symbols, star)
    eval(state)
  end

  def eval(%Expression{tokens: [first | _]} = state) do
    {token_type, _token_details} = first
    new_state = eval(token_type, state)

    cond do
      length(new_state.tokens) == 0 -> validate_end_of_expression(state)
      true -> eval(new_state)
    end
  end

  def eval(
        :operator = _type,
        %Expression{} = state
      ) do
    hd_token = hd(state.tokens)
    e = token_meets_expectation(hd_token, state.expect)

    cond do
      !e -> raise "operator #{hd_token} does not meet expections [#{state.expect}]"
      true -> nil
    end

    hd_operation = state.operation_stack |> hd()

    {state, advance?} =
      case compare_priorities(hd_token, hd_operation) do
        :first_lower -> {eval_top_operator(state), false}
        :equal -> {eval_top_operator(state), false}
        :second_lower -> {push_new_operator(state), true}
      end

    possibly_advance_tokens(state, advance?)
  end

  def eval(
        :symbol = _type,
        %Expression{} = state
      ) do
    state
  end

  def eval(
        :value = _type,
        %Expression{value_stack: value_stack, tokens: [first_token | rest_of_tokens]} = state
      ) do
    {first_token, rest_of_tokens} |> dbg
    {:value, value} = first_token
    # each value on the value_stack is a tuple: {value, relocation}
    %{state | value_stack: [{value, 0} | value_stack], tokens: rest_of_tokens}
  end

  def eval(
        :close_paren = _type,
        %Expression{} = state
      ) do
    relative_priorities = compare_priorities(state)

    cond do
      relative_priorities == :first_lower ->
        new_state = eval_top_operator(state)
        eval(:close_paren, new_state)

      # can be equal only if ( is at the top of the operator stack.
      # pop it and the token and we're done
      relative_priorities == :equal ->
        [_ | new_operation_stack] = state.operation_stack
        [_ | new_tokens] = state.tokens
        %{state | operation_stack: new_operation_stack, tokens: new_tokens}
    end
  end

  def eval_top_operator(%Expression{} = state) do
    {:operator, top_op} = hd(state.operation_stack)

    new_value_stack =
      case top_op do
        "U-" -> eval_negate(state.value_stack)
        "U+" -> state.value_stack
        "*" -> eval_binary(&Kernel.*/2, state.value_stack)
        "/" -> eval_binary(&Kernel.div/2, state.value_stack)
        "+" -> eval_binary(&Kernel.+/2, state.value_stack)
        "-" -> eval_binary(&Kernel.-/2, state.value_stack)
        ")" -> eval_binary(&Kernel.*/2, state.value_stack)
        "(" -> eval_binary(&Kernel.*/2, state.value_stack)
      end

    %{state | value_stack: new_value_stack}
  end

  def eval_negate([{val, relocation} = _top | rest]), do: [{-val, -relocation} | rest]

  def eval_binary(fun, [first | [second | [rest]]]) do
    new_value = fun.(elem(first, 0), elem(second, 0))
    new_relocation = fun.(elem(first, 1), elem(second, 1))
    [{new_value, new_relocation} | rest]
  end

  def possibly_advance_tokens(%Expression{} = state, false), do: state

  def possibly_advance_tokens(%Expression{tokens: tokens} = state, true),
    do: %{state | tokens: tl(tokens)}

  def push_new_operator(%Expression{} = state) do
    state
  end

  def convert_token({:operator, text}, _) do
    case text do
      "(" -> {:open_paren, "("}
      ")" -> {:close_paren, ")"}
      _ -> {:operator, text}
    end
  end

  def convert_token({:symbol, symbol_name}, symbols) do
    symbol = Map.get(symbols, symbol_name, nil)

    cond do
      symbol == nil -> {:undefined, symbol_name}
      true -> {:symbol_value, {symbol.value, symbol.relocation}}
    end
  end

  def convert_token({:number, number_text}, _), do: {:value, Easm.Lexer.number_value(number_text)}

  def convert_token({_type, _op} = token, _), do: token

  def priority({type, op}) when is_binary(op) do
    cond do
      type in [:operator, :open_paren, :close_paren] -> nil
      true -> raise "illegal token on top of operator stack: {#{type}, #{op}}"
    end

    case op do
      "U-" -> 30
      "U+" -> 30
      "*" -> 20
      "/" -> 20
      "+" -> 15
      "-" -> 15
      # code depends on priority of ( equaling the priority of ).
      # Make sure the next two lines reflect that rule.
      ")" -> 5
      "(" -> 5
    end
  end

  def compare_priorities(%Expression{tokens: [first_token | _rest_of_tokens]} = state) do
    compare_priorities(first_token, state)
  end

  def compare_priorities(first, %Expression{operation_stack: [top | _rest]} = _state) do
    {_, top_operator} = top
    compare_priorities(first, top_operator)
  end

  def compare_priorities(first, second) do
    p0 = priority(first)
    p1 = priority(second)

    cond do
      p0 < p1 -> :first_lower
      p0 == p1 -> :equal
      true -> :first_higher
    end
  end

  def token_meets_expectation({type, _text} = _token, expectations) when is_list(expectations),
    do: type in expectations

  def validate_end_of_expression(%Expression{} = state) do
    cond do
      length(state.value_stack) == 1 -> hd(state.value_stack)
      true -> raise "expression error"
    end
  end
end
