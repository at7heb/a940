defmodule Easm.Expression do
  alias Easm.Expression
  # alias Easm.Symbol

  defstruct operation_stack: [],
            value_stack: [],
            expect: [],
            tokens: [],
            star: {0, 0},
            symbols: %{}

  @moduledoc """
  evaluate address expressions, keeping track of the resulting relocation factor
  """

  def new(tokens, symbols, star) do
    new_tokens =
      Enum.map(tokens, fn {type, text} ->
        convert_token({type, text}, symbols)
      end)

    %Expression{
      operation_stack: [{:open_paren, "("}],
      value_stack: [],
      expect: [:symbol, :number, :open_paren, :unary, :askterisk],
      tokens: new_tokens,
      star: star,
      symbols: symbols
    }
  end

  def start_eval(tokens, {value, relocation} = star, symbols)
      when is_list(tokens) and is_integer(value) and is_integer(relocation) and is_map(symbols) do
    state = new(tokens ++ [{:close_paren, ")"}], symbols, star)
    eval(state)
  end

  def eval(%Expression{tokens: [{token_type, _token_details} | _]} = state) do
    new_state = eval(token_type, state)

    cond do
      length(new_state.tokens) == 0 -> validate_end_of_expression(new_state)
      true -> eval(new_state)
    end
  end

  # def eval({value, relocation} = val) when is_integer(value) and is_integer(relocation) do
  #   "eval(value)" |> dbg

  #   val
  # end

  # @spec eval(
  #         :asterisk | :close_paren | :open_paren | :operator | :symbol | :value,
  #         %Easm.Expression{optional(any()) => any()}
  #       ) :: any()
  def eval(
        :operator = _type,
        %Expression{} = state
      ) do
    state = convert_to_unary(state)
    hd_token = hd(state.tokens)
    e = token_meets_expectation(hd_token, state.expect)

    cond do
      !e ->
        {hd_token, state.expect} |> dbg

        raise "operator {#{elem(hd_token, 0)},#{elem(hd_token, 1)}} does not meet expections [#{state.expect}]"

      true ->
        nil
    end

    hd_operation = state.operation_stack |> hd()

    # if  advance to the next token, must change the expect list
    # otherwise keep it as it is.
    {state, new_expect} =
      case compare_priorities(hd_token, hd_operation) do
        :first_lower ->
          {eval_top_operator(state), state.expect}

        :equal ->
          {eval_top_operator(state), state.expect}

        :first_higher ->
          {pop_and_push_new_operator(state), [:open_paren, :symbol, :number, :asterisk]}
      end

    %{state | expect: new_expect}
  end

  def eval(
        :asterisk = _type,
        %Expression{} = state
      ) do
    e1 = token_meets_expectation({:symbol, "A1"}, state.expect)
    e2 = token_meets_expectation({:operator, "*"}, state.expect)
    [_ | rest] = state.tokens

    {new_tokens, new_type} =
      cond do
        e1 and e2 ->
          raise "Improper processing of asterisk token!"

        e1 ->
          {[{:value, state.star} | rest], :value}

        e2 ->
          {[{:operator, "*"} | rest], :operator}
      end

    eval(new_type, %{state | tokens: new_tokens})
  end

  def eval(
        :symbol = _type,
        %Expression{
          symbols: symbols,
          tokens: [{_, symbol_name} | rest_of_tokens]
        } = state
      ) do
    symbol_value = Map.get(symbols, symbol_name)

    new_token =
      cond do
        symbol_value == nil ->
          raise "undefined_expr"

        symbol_value.state == :known ->
          {:value, {symbol_value.value, symbol_value.relocation}}

        true ->
          symbol_value |> dbg
          raise "symbol unknown here"
      end

    new_state = %{
      state
      | tokens: [new_token | rest_of_tokens]
    }

    eval(:value, new_state)
  end

  def eval(
        :value = _type,
        %Expression{value_stack: value_stack, tokens: [first_token | rest_of_tokens]} = state
      ) do
    {:value, value} = first_token

    value_relocation =
      cond do
        is_integer(value) -> {value, 0}
        is_tuple(value) -> value
        true -> raise "unknown value #{value} of :value token"
      end

    # each value on the value_stack is a tuple: {value, relocation}
    %{
      state
      | value_stack: [value_relocation | value_stack],
        tokens: rest_of_tokens,
        expect: [:operator, :asterisk, :close_paren]
    }
  end

  def eval(
        :open_paren = _type,
        %Expression{tokens: [open_paren_op | rest_of_tokens]} = state
      ) do
    case token_meets_expectation(open_paren_op, state.expect) do
      false ->
        raise "open paren in illegal context"

      true ->
        %{
          state
          | tokens: rest_of_tokens,
            operation_stack: [open_paren_op | state.operation_stack],
            expect: [:unary, :asterisk, :symbol, :number, :value]
        }
    end
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
    [{:operator, top_op} | popped_operation_stack] = state.operation_stack

    new_value_stack =
      case top_op do
        "U-" ->
          eval_negate(state.value_stack)

        "U+" ->
          state.value_stack

        "*" ->
          eval_binary(&Kernel.*/2, state.value_stack)

        "/" ->
          eval_binary(&Kernel.div/2, state.value_stack)

        "+" ->
          eval_binary(&Kernel.+/2, state.value_stack)

        "-" ->
          eval_binary(&Kernel.-/2, state.value_stack)
          # ")" -> eval_binary(&Kernel.*/2, state.value_stack)
          # "(" -> eval_binary(&Kernel.*/2, state.value_stack)
      end

    %{state | value_stack: new_value_stack, operation_stack: popped_operation_stack}
  end

  def eval_negate([{val, relocation} = _top | rest]), do: [{-val, -relocation} | rest]

  def eval_binary(fun, [first | [second | rest]]) do
    new_value = fun.(elem(second, 0), elem(first, 0))
    div_fun = &Kernel.div/2
    mul_fun = &Kernel.*/2

    new_relocation =
      cond do
        div_fun == fun and elem(first, 1) == 0 and elem(second, 1) == 0 -> 0
        mul_fun == fun and elem(first, 1) == 0 -> elem(first, 0) * elem(second, 1)
        mul_fun == fun and elem(second, 1) == 0 -> elem(second, 0) * elem(first, 1)
        div_fun != fun -> fun.(elem(second, 1), elem(first, 1))
        true -> raise "illegal relocation of divide expression"
      end

    [{new_value, new_relocation} | rest]
  end

  def possibly_advance_tokens(%Expression{} = state, false), do: state

  def possibly_advance_tokens(%Expression{tokens: tokens} = state, true),
    do: %{state | tokens: tl(tokens)}

  def pop_and_push_new_operator(%Expression{} = state) do
    [new_operator | rest_of_tokens] = state.tokens
    new_operation_stack = [new_operator | state.operation_stack]
    %{state | tokens: rest_of_tokens, operation_stack: new_operation_stack}
  end

  def convert_token({:operator, text}, _) do
    case text do
      "(" -> {:open_paren, "("}
      ")" -> {:close_paren, ")"}
      _ -> {:operator, text}
    end
  end

  # def convert_token({:symbol, symbol_name}, symbols) do
  #   symbol = Map.get(symbols, symbol_name, nil)

  #   cond do
  #     symbol == nil -> {:undefined, symbol_name}
  #     true -> {:symbol_value, {symbol.value, symbol.relocation}}
  #   end
  # end

  def convert_token({:number, number_text}, _), do: {:value, Easm.Lexer.number_value(number_text)}

  def convert_token({_type, _op} = token, _), do: token

  def convert_to_unary(%Expression{tokens: [head_token | rest_of_tokens] = tokens} = state) do
    unary_ok = :unary in state.expect
    maybe_unary_plus = head_token == {:operator, "+"}
    maybe_unary_minus = head_token == {:operator, "-"}

    new_tokens =
      cond do
        not unary_ok -> tokens
        unary_ok and maybe_unary_plus -> [{:operator, "U+"} | rest_of_tokens]
        unary_ok and maybe_unary_minus -> [{:operator, "U-"} | rest_of_tokens]
      end

    %{state | tokens: new_tokens}
  end

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
    compare_priorities(first, top)
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

  def token_meets_expectation({type, text} = _token, expectations) when is_list(expectations) do
    e = type in expectations

    cond do
      e -> e
      type == :operator and text == "U-" and :unary in expectations -> true
      type == :operator and text == "U+" and :unary in expectations -> true
      true -> false
    end
  end

  def validate_end_of_expression(%Expression{} = state) do
    cond do
      length(state.value_stack) == 1 -> hd(state.value_stack)
      true -> raise "expression error"
    end
  end
end
