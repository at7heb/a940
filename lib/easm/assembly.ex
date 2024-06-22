defmodule Easm.Assembly do
  alias Easm.LexicalLine
  alias Easm.ADotOut
  alias Easm.Symbol
  alias Easm.Ops
  alias Easm.Pseudos
  # alias Easm.Memory

  def assemble_lexons(%ADotOut{} = aout, line_number) when is_integer(line_number) do
    aout |> dbg
    lexon_cursor = get_cursor(aout)
    IO.puts("assemble_lexons line #{line_number} lexon #{lexon_cursor}")

    new_aout =
      cond do
        Map.get(aout.lines, line_number, nil) == nil ->
          IO.inspect("at end, or error in line")
          add_flag(aout, :done)

        true ->
          new_aout =
            recognize_comment(aout)
            |> handle_label_part()
            |> handle_operator_part()

          update_aout(new_aout, listing(new_aout), new_aout.file_ok)
      end

    new_aout |> dbg
  end

  def recognize_comment(%ADotOut{} = aout) do
    {%LexicalLine{} = line_lex, _line_position, token} = get_token_info(aout)

    cond do
      token == {:asterisk, "*"} ->
        finish_comment_line(aout, line_lex.original)

      true ->
        aout
    end
  end

  def handle_label_part(%ADotOut{} = aout) do
    # handle 3 cases:
    # whitespace
    # label whitespace
    # $label whitespace
    # after the whitespace, there will be a pseudo or real operator.
    # So thee may be only 2 tokens in a line: whitespace and op
    # a solo whitespace token should already have been eliminated by the string trimming.
    cond do
      has_flag?(aout, :done) ->
        aout

      true ->
        lines = aout.lines
        current_line = Map.get(lines, :current_line)

        handle_label_part(
          aout,
          Map.get(lines, current_line)
          |> Map.get(:tokens)
          |> Enum.take(3)
        )
    end
  end

  def handle_label_part(%ADotOut{} = aout, [white_space: _space, symbol: _] = _lexons) do
    aout |> increment_cursor_by(1) |> finish_part()
  end

  def handle_label_part(%ADotOut{} = aout, [white_space: _space, asterisk: _] = _lexons) do
    {%LexicalLine{} = line_lex, _line_position, _token} = get_token_info(aout)
    finish_comment_line(aout, line_lex.original)
  end

  def handle_label_part(
        %ADotOut{} = aout,
        [_, _] = _lexons
      ) do
    IO.inspect("error case to handle lable part with 2 tokens")
    aout |> increment_cursor_by(1) |> finish_part(false)
  end

  def handle_label_part(
        %ADotOut{} = aout,
        [white_space: _space, symbol: _, white_space: _space2] = _lexons
      ) do
    aout |> increment_cursor_by(1) |> finish_part()
  end

  def handle_label_part(
        %ADotOut{} = aout,
        [symbol: sym, white_space: _, symbol: _] = _lexons
      ) do
    # put symbol in symbol table
    symbol_value = Symbol.symbol(aout)

    update_symbol_table(aout, sym, symbol_value) |> increment_cursor_by(2) |> finish_part()
  end

  def handle_label_part(
        %ADotOut{} = aout,
        [operator: "$", symbol: sym, white_space: _] = _lexons
      ) do
    # put symbol as exported into the symbol table
    symbol_value = %{Symbol.symbol(aout) | type: :exported}

    update_symbol_table(aout, sym, symbol_value) |> increment_cursor_by(3) |> finish_part()
  end

  # error case
  def handle_label_part(
        %ADotOut{} = aout,
        lexons
      ) do
    # put symbol as exported into the symbol table
    IO.inspect(lexons, label: "error case final handle label")
    aout |> increment_cursor_by(3) |> finish_part(false)
  end

  def handle_operator_part(%ADotOut{file_ok: false} = aout) do
    aout
  end

  # cases
  # operator
  # operator whitespace
  # operator whitespace comments
  # operator whitespace expression
  # operator asterisk whitespace expression
  # leave cursor pointing to expression, comments, or end of line
  def handle_operator_part(%ADotOut{lines: lines} = aout) do
    cond do
      has_flag?(aout, :done) ->
        aout

      true ->
        current_line = Map.get(lines, :current_line)
        cursor = get_cursor(aout)

        handle_operator_part(
          aout,
          Map.get(lines, current_line).tokens |> Enum.slice(cursor..(cursor + 2))
        )
    end
  end

  def handle_operator_part(%ADotOut{} = aout, tokens) when is_list(tokens) do
    {:symbol, op} = hd(tokens)
    is_pseudo = Pseudos.pseudo_op_lookup(op)
    is_op = Ops.op_lookup(op)
    {is_indirect, extra_increment} = Ops.op_indirect(Enum.at(tokens, 1)) |> dbg

    {new_aout, okay} =
      cond do
        is_pseudo != :not_pseudo and is_indirect == false ->
          {Pseudos.handle_pseudo(aout, is_pseudo), true}

        is_op != :not_op ->
          {Ops.handle_op(aout, is_op), true}

        true ->
          {aout, false}
      end

    # {tokens, is_pseudo, is_op}
    new_aout |> increment_cursor_by(1 + extra_increment) |> finish_part(okay)
  end

  @address_width 5
  @content_width 8

  def add_flag(%ADotOut{flags: flags} = aout, flag) when is_atom(flag) do
    cond do
      flag not in flags -> %{aout | flags: [flag | flags]}
      true -> aout
    end
  end

  def listing(%ADotOut{} = aout) do
    already_listed = aout.lines |> Map.get(:line_ok) == false

    cond do
      already_listed ->
        "already listed; line_ok = #{Map.get(aout.lines, :line_ok)}" |> dbg

      true ->
        mem = hd(aout.memory)
        location = mem.location
        relocatable? = mem.relocatable?
        content = mem.content

        location_tag =
          (Integer.to_string(location, 8)
           |> String.pad_leading(@address_width, "0")) <> if relocatable?, do: " ", else: "A"

        content_tag = Integer.to_string(content, 8) |> String.pad_leading(@content_width, "0")

        {%LexicalLine{original: original} = _line_lex, _line_position, _token} =
          get_token_info(aout)

        " #{location_tag} #{content_tag}  #{original}"
    end
  end

  def listing(text) when is_binary(text) do
    " #{String.duplicate(" ", @address_width)}  #{String.duplicate(" ", @content_width)}  #{text}"
  end

  def finish_comment_line(%ADotOut{} = aout, line_text) do
    update_aout(aout, listing(line_text), true) |> add_flag(:done)
  end

  def finish_part(%ADotOut{} = aout, okay \\ true) when is_boolean(okay) do
    cond do
      okay -> aout
      true -> line_is_not_okay(aout, "LABEL")
    end
  end

  def get_cursor(%ADotOut{} = aout) do
    lines = aout.lines
    Map.get(lines, :line_cursor)
  end

  def get_token_info(%ADotOut{lines: lines} = _aout) do
    lex_line = Map.get(lines, lines.current_line)
    {lex_line, lines.line_cursor, Enum.at(lex_line.tokens, lines.line_cursor)}
  end

  def has_flag?(%ADotOut{flags: flags} = _aout, flag) do
    flag in flags
  end

  # these two increment cursor functions are the equivalent of set/put cursor
  def increment_cursor(%ADotOut{} = aout) do
    increment_cursor_by(aout, 1)
  end

  def increment_cursor_by(%ADotOut{} = aout, n) when is_integer(n) and n > 0 do
    new_cursor = n + get_cursor(aout)
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

    %{aout | lines: new_lines, label: nil}
    |> remove_flag(:done)
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
  end

  def update_listing_if_error(%ADotOut{} = aout, message \\ "unk") do
    cond do
      aout.lines.line_ok == false or has_flag?(aout, :recognized_one) ->
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
    %{aout | symbols: new_symbols, label: symbol}
  end
end
