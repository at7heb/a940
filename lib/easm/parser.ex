defmodule Easm.Parser do
  alias Easm.ADotOut
  alias Easm.LexicalLine
  alias Easm.Symbol

  def build_symbol_table(%LexicalLine{tokens: []} = _line, %ADotOut{} = aout),
    do: aout

  def build_symbol_table(
        %LexicalLine{tokens: [{:asterisk, "*"}]} = _line,
        %ADotOut{} = aout
      ),
      do: aout

  def build_symbol_table(
        %LexicalLine{tokens: [{:white_space, _}]} = _line,
        %ADotOut{} = aout
      ),
      do: aout

  def build_symbol_table(%LexicalLine{tokens: tokens}, %ADotOut{} = aout) do
    {_new_tokens, new_aout} = build_symbol_table(tokens, aout)
    new_aout
  end

  def build_symbol_table(
        tokens,
        %ADotOut{} = aout
      )
      when is_list(tokens) do
    [h | t] = tokens

    {new_tokens, new_aout, recurse_flag} =
      cond do
        {:operator, "$"} == h ->
          {t, set_flag(aout, :export_symbol), true}

        {:symbol, sym} = h ->
          new_aout =
            if :export_symbol in aout.flags do
              add_exported_symbol(aout, sym)
            else
              add_symbol(aout, sym)
            end

          {t, new_aout |> clear_flag(:export_symbol), false}

        true ->
          {tokens, aout, false}
      end

    if recurse_flag do
      build_symbol_table(new_tokens, new_aout)
    else
      {new_tokens, new_aout}
    end
  end

  def set_flag(%ADotOut{flags: flags} = aout, flag) do
    cond do
      flag in flags -> aout
      true -> %{aout | flags: [flag | flags]}
    end
  end

  def clear_flag(%ADotOut{flags: flags} = aout, flag) do
    cond do
      flag in flags -> %{aout | flags: List.delete(flags, flag)}
      true -> aout
    end
  end

  def add_symbol(aout, symbol) do
    symbol_value = Symbol.symbol(aout)
    update_symbol_table(aout, symbol, symbol_value)
  end

  def add_exported_symbol(aout, symbol) do
    symbol_value = %{Symbol.symbol(aout) | exported: true}
    update_symbol_table(aout, symbol, symbol_value)
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
    %{aout | symbols: new_symbols}
  end
end
