defmodule Easm.Assembly do
  alias Easm.LexicalLine
  alias Easm.ADotOut
  alias Easm.Symbol
  alias Easm.Ops

  def assemble_lexons(%ADotOut{} = aout, line_number) when is_integer(line_number) do
    lexon_cursor = get_cursor(aout)
    IO.puts("assemble_lexons line #{line_number} lexon #{lexon_cursor}")
    Map.get(aout.lines, line_number, nil)
    Map.get(aout.lines, :line_ok)

    cond do
      Map.get(aout.lines, line_number, nil) == nil or
          Map.get(aout.lines, :line_ok) ==
            false ->
        IO.inspect("at end, or error in line")
        aout

      true ->
        recognize_comment(aout)
        |> recognize_export_indicator()
        |> recognize_symbol_definition()
        |> recognize_white_space()
        |> recognize_operator()
        |> update_listing_if_error()
        |> increment_cursor()
        |> remove_flag(:recognized_one)
        |> assemble_lexons(line_number)
    end
  end

  def recognize_comment(%ADotOut{} = aout) do
    {%LexicalLine{} = line_lex, line_position, token} = get_token_info(aout)

    aout.file_ok |> dbg

    cond do
      token == {:asterisk, "*"} ->
        new_line_listing = listing(line_lex)
        update_aout(aout, new_line_listing, true) |> add_flag(:recognized_one)

      true ->
        aout
    end
    |> remove_flag(:symbol_definition_ok)
  end

  def recognize_export_indicator(%ADotOut{} = aout) do
    # E.G. $NUM2STR ZRO N2SRET
    # the dollar sign is the first element
    # it must be followed by a symbol
    # in this case, set the flag so the symbol will be exported
    lines = aout.lines
    cursor = Map.get(lines, :line_cursor)
    current_line = Map.get(lines, :current_line)
    lexons = Map.get(lines, current_line) |> Map.get(:tokens)

    cond do
      cursor > 0 ->
        aout

      Enum.at(lexons, 0) == {:operator, "$"} and elem(Enum.at(lexons, 1), 0) == :symbol ->
        add_flag(aout, :export_the_symbol) |> add_flag(:recognized_one)

      Enum.at(lexons, 0) == {:operator, "$"} ->
        line_is_not_okay(aout, "e:#{0}")

      true ->
        aout
    end
  end

  def recognize_symbol_definition(%ADotOut{} = aout) do
    {%LexicalLine{} = line_lex, line_position, lexon} = get_token_info(aout)
    # lexons = line_lex.tokens
    {type, val} = lexon

    cond do
      type == :symbol and has_flag?(aout, :symbol_definition_ok) ->
        symbol_value = Symbol.symbol(aout)

        update_symbol_table(aout, val, symbol_value)
        |> remove_flag(:symbol_definition_ok)
        |> add_flag(:recognized_one)
        |> dbg

      type == :symbol and line_position == 1 and has_flag?(aout, :export_the_symbol) ->
        symbol_value = %{Symbol.symbol(aout) | type: :exported}

        update_symbol_table(aout, val, symbol_value)
        |> remove_flag(:export_the_symbol)
        |> remove_flag(:symbol_definition_ok)
        |> add_flag(:recognized_one)
        |> dbg

      true ->
        aout
    end
  end

  def recognize_white_space(%ADotOut{} = aout) do
    {%LexicalLine{} = line_lex, line_position, lexon} = get_token_info(aout)
    # lexons = line_lex.tokens
    {type, val} = lexon

    cond do
      type == :white_space and has_flag?(:need_first_white_space) ->
        remove_flag(aout, :need_first_white_space)
        |> add_flag(:need_operator)
        |> add_flag(:recognized_one)

      true ->
        aout
    end
  end

  def recognize_operator(%ADotOut{} = aout) do
    {%LexicalLine{} = line_lex, line_position, lexon} = get_token_info(aout)
    # lexons = line_lex.tokens
    {type, val} = lexon

    cond do
      type == :operator and has_flag?(:need_operator) ->
        nil
    end
  end

  @address_width 5
  @content_width 8

  def add_flag(%ADotOut{flags: flags} = aout, flag) when is_atom(flag) do
    cond do
      flag not in flags -> %{aout | flags: [flag | flags]}
      true -> aout
    end
  end

  def listing(text) when is_binary(text) do
    " #{String.duplicate(" ", @address_width)} #{String.duplicate(" ", @content_width)}  #{text}"
  end

  def get_cursor(%ADotOut{} = aout) do
    lines = aout.lines
    Map.get(lines, :line_cursor)
  end

  def get_token_info(%ADotOut{lines: lines} = _aout) do
    lex_line = Map.get(lines, lines.current_line)
    {lex_line, lines.line_cursor, Map.get(lex_line.tokens, lines.line_cursor)} |> dbg
  end

  def has_flag?(%ADotOut{flags: flags} = _aout, flag) do
    flag in flags
  end

  def increment_cursor(%ADotOut{} = aout) do
    new_cursor = 1 + get_cursor(aout)
    new_lines = Map.put(aout.lines, :line_cursor, new_cursor)
    %{aout | lines: new_lines}
  end

  def initialize_for_a_line_assembly(%ADotOut{} = aout, current_line)
      when is_integer(current_line) do
    new_lines =
      Map.put(aout.lines, :current_line, current_line)
      |> Map.put(:line_ok, true)
      |> Map.put(:finished_with_line, false)
      |> Map.put(:line_cursor, 0)

    # |> dbg

    %{aout | lines: new_lines}
    |> add_flag(:symbol_definition_ok)
    |> add_flag(:need_first_white_space)
  end

  def line_is_not_okay(aout, message) do
    new_lines = Map.put(aout.lines, :line_ok, false)
    update_listing_if_error(%{aout | lines: new_lines}, message)
  end

  def remove_flag(%ADotOut{flags: flags} = aout, flag) when is_atom(flag) do
    new_flags = Enum.filter(flags, &(flag != &1))
    %{aout | flags: new_flags}
  end

  def update_aout(%ADotOut{} = aout, new_line_listing, ok?) when is_boolean(ok?) do
    new_lines =
      Map.put(aout.lines, :finished_with_line, true)
      |> Map.put(:line_ok, ok?)

    %{
      aout
      | listing: [new_line_listing | aout.listing],
        lines: new_lines,
        file_ok: aout.file_ok and ok?
    }
    |> dbg
  end

  def update_listing_if_error(%ADotOut{} = aout, message \\ "unk") do
    cond do
      aout.lines.line_ok == false or has_flag(aout, :recognized_one) ->
        text = Map.get(aout.lines, aout.lines.current_line) |> Map.get(:original)
        listing_line = " ERROR #{String.pad_trailing(message, @content_width)}  #{text}"
        update_aout(aout, listing_line, false)

      true ->
        aout
    end
  end

  def update_symbol_table(%ADotOut{symbols: symbols} = aout, symbol, %Symbol{} = symbol_value)
      when is_binary(symbol) do
    existing_symbol = Map.get(symbols, symbol, nil)

    new_symbol_value =
      cond do
        existing_symbol == nil ->
          symbol_value

        existing_symbol.known == false ->
          %{Symbol.symbol() | known: {:error, :multiply_defined}}
      end

    new_symbols = Map.put(symbols, symbol, new_symbol_value)
    %{aout | symbols: new_symbols}
  end
end
