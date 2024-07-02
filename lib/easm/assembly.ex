defmodule Easm.Assembly do
  alias Easm.LexicalLine
  alias Easm.ADotOut
  alias Easm.Symbol
  alias Easm.Ops
  # alias Easm.Pseudos
  # alias Easm.Address
  alias Easm.Lexer
  alias Easm.Memory

  def assemble_lexons(%ADotOut{} = aout, line_number) when is_integer(line_number) do
    lexon_cursor = get_cursor(aout)
    IO.puts("assemble_lexons line #{line_number} lexon #{lexon_cursor}")
    # |> dbg
    Map.get(aout.lines, line_number)

    cond do
      Map.get(aout.lines, line_number, nil) == nil ->
        IO.inspect("at end, or error in line")
        add_flag(aout, :done)

      true ->
        aout
        |> clean_for_new_statement()

        recognize_comment(aout)
        # |> parse_out_parts()
        |> handle_label_part()
        |> Ops.handle_operator_part()
        # |> resolve_addresses()
        # |> update_memory()
        |> update_aout()
    end
  end

  def recognize_comment(%ADotOut{} = aout) do
    {%LexicalLine{} = line_lex, _line_position, token} = get_token_info(aout)

    cond do
      token == [] ->
        # "null line" |> dbg
        finish_comment_line(aout, line_lex.original)

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
    # So there may be only 2 tokens in a line: whitespace and op
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
        )
    end
  end

  def handle_label_part(%ADotOut{} = aout, %LexicalLine{label_tokens: label_tokens} = _lex_line) do
    n_tokens = length(label_tokens)

    cond do
      n_tokens == 0 ->
        aout |> finish_part()

      n_tokens == 1 and Lexer.token_type(hd(label_tokens)) == :symbol ->
        symbol_name = Lexer.token_value(hd(label_tokens))
        symbol_value = Symbol.symbol(aout)

        %{aout | label: symbol_name}
        |> update_symbol_table(symbol_name, symbol_value)
        |> finish_part()

      n_tokens == 2 and Lexer.token_type(hd(label_tokens)) == :operator and
        Lexer.token_value(hd(label_tokens)) == "$" and
          Lexer.token_type(Enum.at(label_tokens, 1)) == :symbol ->
        symbol_name = Lexer.token_value(Enum.at(label_tokens, 1))
        symbol_value = %{Symbol.symbol(aout) | exported: true}

        %{aout | label: symbol_name}
        |> update_symbol_table(symbol_name, symbol_value)
        |> finish_part()

      true ->
        IO.inspect("error case to handle lable part")
        finish_part(aout, false)
    end
  end

  def handle_address_part(%ADotOut{file_ok: false} = aout) do
    aout
  end

  @address_width 5
  @content_width 8

  def add_flag(%ADotOut{flags: flags} = aout, flag) when is_atom(flag) do
    cond do
      flag not in flags -> %{aout | flags: [flag | flags]}
      true -> aout
    end
  end

  def clean_for_new_statement(%ADotOut{} = aout) do
    aout
    |> Memory.clean_for_new_statement()
    |> LexicalLine.clean_for_new_statement()
    |> ADotOut.clean_for_new_statement()
    |> Lexer.clean_for_new_statement()
    |> Ops.clean_for_new_statement()
  end

  def listing(%ADotOut{} = aout) do
    already_listed = aout.lines |> Map.get(:line_ok) == false

    cond do
      already_listed ->
        "already listed; line_ok = #{Map.get(aout.lines, :line_ok)}" |> dbg

      aout.memory == [] ->
        "no memory" |> dbg

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

  def update_aout(%ADotOut{} = aout), do: update_aout(aout, listing(aout), aout.file_ok)

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
          %{Symbol.symbol() | state: {:error, :multiply_defined}}
      end

    new_symbols = Map.put(symbols, symbol, new_symbol_value)
    %{aout | symbols: new_symbols, label: symbol}
  end
end
