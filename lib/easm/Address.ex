defmodule Easm.Address do
  alias Easm.Memory
  alias Easm.ADotOut
  alias Easm.Assembly
  alias Easm.LexicalLine
  alias Easm.Lexer
  alias Easm.Ops
  alias Easm.Symbol
  alias Easm.Address
  import Bitwise

  defstruct type: 0,
            constant: 0,
            symbol_name: "",
            symbol: Symbol,
            indexed?: false

  @moduledoc """
   handle the address part of the statement.
   the type can be atom value of unknown, constant, or a symbol
   the symbol name is returned; it's value isn't needed until
   the whole file has been processed, or until the link edit phase.
   indexed? is true when address field ends with ,2

   This module must create the symbols; the caller must put them into the symbol table.

   Symbols can be simple symbols like STARTGC
   Symbols can be literals like =12525253B
   Symbols can be expressions like *+5
  """

  def new(
        type \\ :unknown,
        constant \\ 0,
        symbol_name \\ "",
        symbol \\ %Symbol{},
        indexed? \\ false
      ) do
    %Address{
      type: type,
      constant: constant,
      symbol_name: symbol_name,
      symbol: symbol,
      indexed?: indexed?
    }
  end

  def get_address(%ADotOut{lines: lines} = aout) do
    get_address(
      aout,
      lines.current_line,
      Map.get(lines, lines.current_line)
    )
  end

  def get_address(%ADotOut{} = _aout, current_line, %LexicalLine{address_tokens: []} = _lex_line)
      when is_integer(current_line),
      do: new(:no_address)

  def get_address(
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
        %{constant_value | indexed?: is_indexed?}

      is_literal? ->
        literal_address(aout, current_line, literal_tokens, is_indexed?)

      is_symbol? ->
        symbol_address(aout, symbol_token, is_indexed?)

      is_expression? ->
        address_expression(aout, current_line, expression_tokens, is_indexed?)
    end

    # |> dbg
  end

  def literal_address(%ADotOut{} = _aout, current_line, tokens, is_indexed?)
      when is_integer(current_line) and is_list(tokens) do
    {tokens, is_indexed?, "literal_address"} |> dbg
    {:constant, 100}
  end

  def symbol_address(%ADotOut{} = aout, symbol_token, is_indexed?) do
    {symbol_token, is_indexed?, "symbol_address"} |> dbg()
    symbol_table_entry = Map.get(aout.symbols, symbol_token)
    {symbol_token, symbol_table_entry} |> dbg

    symbol_table_entry1 =
      cond do
        symbol_table_entry == nil -> Symbol.new()
        true -> symbol_table_entry
      end

    new(
      :referenced,
      0,
      symbol_token,
      symbol_table_entry1,
      is_indexed?
    )
  end

  def address_expression(%ADotOut{} = _aout, current_line, tokens, is_indexed?)
      when is_integer(current_line) and is_list(tokens) do
    {tokens, is_indexed?, "expression address"} |> dbg

    symbol =
      Symbol.new(
        state: :defined,
        value: nil,
        relocatable: true,
        definition: tokens,
        exported: false
      )

    new(
      :referenced,
      0,
      Symbol.generate_name(:expression),
      struct(Symbol, symbol.value),
      is_indexed?
    )
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
        {true, new(:constant, Lexer.number_value(hd(addr_tokens) |> elem(1)))}

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

  def handle_address_constant(
        %ADotOut{memory: memory_list} = aout,
        [constant_value],
        is_indexed?
      )
      when is_list(memory_list) do
    [recent_word | rest_of_memory] = memory_list
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

    new_value =
      Memory.get_content(recent_word) + masked_constant_value + Ops.index_bit(is_indexed?)

    new_word = Memory.update_content(recent_word, new_value)
    %{aout | memory: [new_word | rest_of_memory]}
  end

  def handle_address_literal(
        %ADotOut{} = aout,
        _current_line,
        [{:operator, "="}, {:number, number_text}] = tokens,
        _is_indexed?
      ) do
    symbol_value = Lexer.number_value(number_text)
    symbol_name = Symbol.generate_name(:literal)
    new_symbol = Symbol.new(symbol_value, tokens, :known)
    ADotOut.add_symbol(aout, symbol_name, new_symbol)
  end

  def handle_address_literal(
        %ADotOut{} = aout,
        _current_line,
        _literal_tokens,
        _is_indexed?
      ) do
    aout
  end

  def handle_address_symbol(%ADotOut{} = _aout, _symbol_token, _is_indexed?) do
  end

  def handle_address_expression(
        %ADotOut{} = _aout,
        _current_line,
        _expression_tokens,
        _is_indexed?
      ) do
  end

  def handle_address_part(%ADotOut{lines: lines} = aout) do
    cond do
      Assembly.has_flag?(aout, :done) ->
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
        _current_line,
        %LexicalLine{address_tokens: []} = _lex_line
      ),
      do: aout

  def handle_address_part(
        %ADotOut{} = aout,
        _current_line,
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
end
