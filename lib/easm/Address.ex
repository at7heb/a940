defmodule Easm.Address do
  alias Easm.ADotOut
  alias Easm.Assembly
  alias Easm.LexicalLine

  def handle_address_part(%ADotOut{} = aout) do
    {%LexicalLine{} = line_lex, _line_position, token} = Assembly.get_token_info(aout)
    {line_lex, token} |> dbg
    aout
  end
end
