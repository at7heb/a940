defmodule Easm.Assembly do
  alias Easm.LexicalLine
  alias Easm.ADotOut

  def assemble_lexons(%ADotOut{} = aout, line_number) when is_integer(line_number) do
    lexon_cursor = get_cursor(aout)

    cond do
      Enum.at(aout.lines, lexon_cursor, nil) == nil or Map.get(aout.lines, :line_ok) == false ->
        aout

      true ->
        recognize_comment(aout)
        |> recognize_export_indicator()
        |> recognize_symbol()
        |> update_listing_if_error()
        |> increment_cursor()
        |> assemble_lexons(line_number)
    end
  end

  def recognize_comment(%ADotOut{} = aout) do
    {%LexicalLine{} = line_lex, line_position} = get_token_info(aout)

    aout.file_ok |> dbg

    cond do
      (line_position == 0 and Enum.at(line_lex.tokens, line_position) == {:asterisk, "*"}) or
          (line_position == 0 and {:white_space, " "} == Enum.at(line_lex.tokens, line_position) and
             (line_position == 1 and Enum.at(line_lex.tokens, line_position) == {:asterisk, "*"})) ->
        new_line_listing = listing(line_lex)

        update_aout(aout, new_line_listing, true)

      true ->
        aout.file_ok |> dbg
        aout
    end
  end

  def recognize_export_indicator(%ADotOut{} = aout) do
    # E.G. $NUM2STR ZRO N2SRET
    # the dollar sign is the first element
    # it must be followed by a symbol
    # in this case, set the flag so the symbol will be exported
    lines = aout.lines
    cursor = Map.get(lines, :line_cursor)
    current_line = Map.get(lines, :current_line)
    lexons = Map.get(lines, current_line)

    cond do
      cursor > 0 ->
        aout

      Enum.at(lexons, 0) == {:operator, "$"} and elem(Enum.at(lexons, 1), 0) == :symbol ->
        add_flag(aout, :export_the_symbol)

      Enum.at(lexons, 0) == {:operator, "$"} ->
        line_is_not_okay(aout, "e:#{0}")

      true ->
        aout
    end
  end

  def recognize_symbol(%ADotOut{lines: lines} = aout) do
    {%LexicalLine{} = line_lex, line_position} = get_token_info(aout)
    lexons = line_lex.tokens
    {type, val} = Enum.at(lexons, line_position)

    cond do
      type == :symbol and line_position == 0 ->
        symbol_value = Symbol.symbol(aout)
        update_symbol_table(aout, symbol, symbol_value)
        type == :symbol and line_position == 1 and has_flag?(aout, :export_the_symbolo)

      true ->
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
    {Map.get(lines, lines.current_line), lines.line_cursor}
  end

  def has_flag?(%ADotOut{flags: flags} = aout, flag) do
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
      |> Map.put(:line_ok, false)
      |> Map.put(:finished_with_line, false)
      |> Map.put(:line_cursor, 0)

    # |> dbg

    %{aout | lines: new_lines}
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
      aout.lines.line_ok == false ->
        text = Map.get(aout.lines, aout.lines.current_line) |> Map.get(:original)
        listing_line = " ERROR #{String.pad_trailing(message, @content_width)}  #{text}"
        update_aout(aout, listing_line, false)

      true ->
        aout
    end
  end
end
