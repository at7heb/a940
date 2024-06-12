defmodule Easm.Assembly do
  alias Easm.LexicalLine
  alias Easm.ADotOut

  def assemble_line(%ADotOut{} = aout, line_number) when is_integer(line_number) do
    aout.file_ok |> dbg

    aout =
      initialize_for_a_line_assembly(aout, line_number)
      |> recognize_comment()
      |> update_listing_if_error()

    # |> Map.put(:file_ok, aout.file_ok and Map.get(aout.lines, :line_ok))

    aout.file_ok |> dbg()
    aout
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

  def initialize_for_a_line_assembly(%ADotOut{} = aout, current_line)
      when is_integer(current_line) do
    new_lines =
      Map.put(aout.lines, :current_line, current_line)
      |> Map.put(:line_ok, false)
      |> Map.put(:finished_with_line, false)

    # |> dbg

    %{aout | lines: new_lines}
  end

  def get_token_info(%ADotOut{lines: lines} = _aout) do
    {Map.get(lines, lines.current_line), lines.line_cursor}
  end

  @address_width 5
  @content_width 8
  def listing(text) when is_binary(text) do
    " #{String.duplicate(" ", @address_width)} #{String.duplicate(" ", @content_width)}  #{text}"
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

  def update_listing_if_error(%ADotOut{} = aout) do
    cond do
      aout.lines.line_ok == false ->
        text = Map.get(aout.lines, aout.lines.current_line) |> Map.get(:original)
        listing_line = " ERROR #{String.duplicate(" ", @content_width)}  #{text}"
        update_aout(aout, listing_line, false)

      true ->
        aout
    end
  end
end
