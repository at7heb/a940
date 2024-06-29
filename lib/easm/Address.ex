defmodule Easm.Address do
  alias Easm.Memory
  alias Easm.ADotOut
  alias Easm.Assembly
  alias Easm.LexicalLine
  alias Easm.Lexer
  alias Easm.Ops
  import Bitwise

  def handle_address_part(%ADotOut{lines: lines} = aout) do
    cond do
      Assembly.has_flag?(aout, :done) ->
        aout

      !address_allowed(aout) ->
        aout

      true ->
        handle_address_part(
          aout,
          lines.current_line,
          Map.get(lines, lines.current_line)
        )
    end
  end

  def handle_address_part(
        %ADotOut{} = aout,
        current_line,
        %LexicalLine{address_tokens: []} = _lex_line
      ),
      do: aout

  def handle_address_part(
        %ADotOut{} = aout,
        current_line,
        %LexicalLine{address_tokens: [{:asterisk, "*"} | _rest]} = _lex_line
      ),
      do: aout

  def handle_address_part(
        %ADotOut{} = aout,
        current_line,
        %LexicalLine{address_tokens: addr_tokens} = _lex_line
      )
      when is_integer(current_line) do
    {is_indexed?, non_indexed_addr_tokens} = is_indexed(addr_tokens)
    {is_constant?, constant_value} = is_constant(non_indexed_addr_tokens)
    {is_literal?, literal_tokens} = is_literal(non_indexed_addr_tokens)
    {is_symbol?, symbol_token} = is_symbol(non_indexed_addr_tokens)
    {is_expression?, expression_tokens} = is_expression(non_indexed_addr_tokens)

    cond do
      is_constant? ->
        handle_address_constant(aout, constant_value, is_indexed?)

      is_literal? ->
        handle_address_literal(aout, current_line, literal_tokens, is_indexed?)

      is_symbol? ->
        handle_address_symbol(aout, symbol_token, is_indexed?)

      is_expression? ->
        handle_address_expression(aout, current_line, expression_tokens, is_indexed?)
    end
  end

  def is_indexed(addr_tokens) when is_list(addr_tokens) do
    n_tokens = length(addr_tokens)
    is_indexed(addr_tokens, n_tokens)
  end

  def is_indexed(addr_tokens, n_tokens) when n_tokens < 3, do: {false, addr_tokens}

  def is_indexed(addr_tokens, _n_tokens) do
    [token0, token1] = Enum.slice(addr_tokens, -2, 2)
    is_indexed(addr_tokens, token0, token1)
  end

  def is_indexed(addr_tokens, {:operator, ","}, {:number, "2"}),
    do: {true, Enum.slice(addr_tokens, 0, length(addr_tokens) - 2)}

  def is_indexed(addr_tokens, _, _), do: {false, addr_tokens}

  def is_constant(addr_tokens) when is_list(addr_tokens) do
    cond do
      length(addr_tokens) == 1 and Lexer.token_type(hd(addr_tokens)) == :number ->
        {true, addr_tokens}

      true ->
        {false, addr_tokens}
    end
  end

  def is_literal([first | rest] = addr_tokens) when is_list(addr_tokens) do
    cond do
      {:operator, "="} == first and length(rest) > 0 -> {true, rest}
      true -> {false, addr_tokens}
    end
  end

  def is_expression(addr_tokens) when is_list(addr_tokens) do
    cond do
      length(addr_tokens) > 1 -> {true, addr_tokens}
      true -> {false, addr_tokens}
    end
  end

  def is_symbol(addr_tokens) when is_list(addr_tokens) do
    cond do
      length(addr_tokens) == 1 and Lexer.token_type(hd(addr_tokens)) == :symbol ->
        {true, Lexer.token_value(hd(addr_tokens))}

      true ->
        {false, addr_tokens}
    end
  end

  def address_allowed(%ADotOut{memory: memory} = _aout) do
    cond do
      Memory.address_field_type(memory) == :no_addr -> false
      true -> true
    end
  end

  def handle_address_constant(
        %ADotOut{memory: [recent_word | rest_of_memory]} = aout,
        [constant_value],
        is_indexed?
      ) do
    type = Memory.address_field_type(recent_word)
    {:number, text_value} = constant_value
    numeric_value = Lexer.number_value(text_value)

    masked_constant_value =
      case type do
        :shift_addr -> numeric_value &&& 0o777
        :rch_addr -> numeric_value &&& 0o37777
        :mem_addr -> numeric_value &&& 0o37777
        _ -> {:error, "illegal address type in instruction"}
      end

    new_value = Memory.content(recent_word) + masked_constant_value + Ops.index_bit(is_indexed?)
    new_word = Memory.update_content(recent_word, new_value)
    %{aout | memory: [new_word | rest_of_memory]}
  end

  def handle_address_literal(
        %ADotOut{memory: memory} = aout,
        current_line,
        [{:operator, "="}, {:number, number_text}] = tokens,
        is_indexed?
      ) do
    symbol_value = Lexer.number_value(number_text)
    symbol_name = Symbol.generate_name(:literal)
    new_symbol = Symbol.new(symbol_value, tokens, :known)
    ADotOut.add_symbol(aout, symbol_name, new_symbol)
  end

  def handle_address_literal(
        %ADotOut{memory: memory} = aout,
        current_line,
        literal_tokens,
        is_indexed?
      ) do
  end

  def handle_address_symbol(%ADotOut{memory: memory} = aout, symbol_token, is_indexed?) do
  end

  def handle_address_expression(%ADotOut{} = aout, current_line, _expression_tokens, _is_indexed?) do
  end
end
