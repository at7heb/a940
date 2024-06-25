defmodule Easm.Address do
  alias Easm.ADotOut
  alias Easm.Assembly
  alias Easm.LexicalLine

  def handle_address_part(%ADotOut{lines: lines} = aout) do
    cond do
      Assembly.has_flag?(aout, :done) ->
        aout

      true ->
        handle_address_part(
          aout,
          Map.get(lines, lines.current_line)
        )
    end
  end

  def handle_address_part(
        %ADotOut{} = aout,
        %LexicalLine{address_tokens: addr_tokens} = _lex_line
      ) do
    {is_indexed?, non_indexed_addr_tokens} = Address.is_indexed(addr_tokens)
    {is_constant?, value} = Address.is_constant(non_indexed_addr_tokens)
    {is_literal?, literal_symbol} = Address.is_literal(non_indexed_addr_tokens)
    {is_expression?, expression_tokens} = Address.is_expression(non_indexed_addr_tokens)
  end

  def is_indexed(addr_tokens) when is_list(addr_tokens) do
    n_tokens = length(addr_tokens)
    is_indexed(addr_tokens, n_tokens)
  end

  def is_indexed(addr_tokens, n_tokens) when n_tokens < 3, do: {false, addr_tokens}

  def is_indexed(addr_tokens, n_tokens) do
    [token0, token1] = Enum.slice(addr_tokens, -2, 2)
    is_indexed(addr_tokens, token0, token1)
  end

  def is_indexed(addr_tokens, {:operator, ","}, {:number, "2"}),
    do: {true, Enum.slice(addr_tokens, 0, length(addr_tokens) - 2)}

  def is_indexed(addr_tokens, _, _), do: {false, addr_tokens}

  def is_constant(addr_tokens) when is_list(addr_tokens) do
  end

  def is_literal(addr_tokens) when is_list(addr_tokens) do
  end

  def is_expression(addr_tokens) when is_list(addr_tokens) do
  end
end
