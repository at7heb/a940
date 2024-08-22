defmodule Easm.Resolver do
  alias Easm.Symbol
  alias Easm.ADotOut
  alias Easm.Expression

  def resolve_symbols(%ADotOut{} = aout) do
    unknown_symbols = get_unknown_symbols(aout)
    resolve_symbols(aout, unknown_symbols, length(unknown_symbols))
  end

  @doc """
  helper
  """
  def resolve_symbols(%ADotOut{} = aout, unknown_symbols, current_count),
    do: resolve_symbols(aout, unknown_symbols, current_count + 1, current_count)

  @doc """
  try to define (:unknown to :known state) as many symbols as possible.
  then update the symbol table entries for those symbols so their state is :known

  An optimization is to update the symbol table each time a symbol is defined.
  Even with such an optimization, this code could be n ** 2 complexity
  if each symbol depends on the next, so only the last is defined each pass.
  First make it work, then make it beautiful, then optimize if necessary.
  MIW, MIB, OIN
  """
  def resolve_symbols(%ADotOut{} = aout, _unknown_symbols, _previous_count, 0 = _current_count),
    do: aout

  def resolve_symbols(%ADotOut{} = aout, _unknown_symbols, previous_count, current_count)
      when previous_count == current_count do
    aout
  end

  def resolve_symbols(%ADotOut{} = aout, unknown_symbols, previous_count, current_count)
      when previous_count > current_count do
    newly_defined_symbols =
      Enum.map(unknown_symbols, fn {name, symbol} = _syms ->
        {name, Expression.try_evaluating_expression(symbol.definition, aout.symbols)}
      end)
      |> Enum.filter(fn {_name, expression} -> expression != nil end)

    new_symbol_table = update_symbol_table(aout.symbols, newly_defined_symbols)
    new_aout = %{aout | symbols: new_symbol_table}

    resolve_symbols(
      new_aout,
      get_unknown_symbols(new_aout),
      current_count,
      current_count - length(newly_defined_symbols)
    )
  end

  def update_symbol_table(%{} = symbol_table, symbol_definitions)
      when is_list(symbol_definitions) do
    Enum.reduce(symbol_definitions, symbol_table, fn one_definition, symbols ->
      update_symbol_table(symbols, one_definition)
    end)
  end

  def update_symbol_table(%{} = symbol_table, {symbol_name, value}) do
    symbol = Map.get(symbol_table, symbol_name)
    new_symbol = %{symbol | state: :known, value: value, definition: []}
    # {symbol_name, symbol, new_symbol} |> dbg
    Map.put(symbol_table, symbol_name, new_symbol)
  end

  @doc """
  returns {name, %symbol{}} for each expression symbol in aout's memory
  This may need to go into aout.
  """
  def addresses_needing_resolution(%ADotOut{} = aout) do
    aout.memory
    |> Enum.filter(fn mem ->
      is_binary(mem.symbol_name) and String.starts_with?(mem.symbol_name, "E_")
    end)
    |> Enum.map(fn mem -> mem.symbol_name end)
    |> Enum.map(fn name -> {name, Map.get(aout.symbols, name)} end)
  end

  def try_resolving(%ADotOut{} = _aout) do
  end

  def try_resolving_one(%Symbol{} = symbol, %{} = symbols) do
    tokens = symbol.definition
    # nonsense value
    star = {16383, 5}
    _value = Expression.start_eval(tokens, star, symbols) |> dbg
  end

  def count_known_symbols(%ADotOut{} = aout) do
    symbols = aout.symbols
    # symbol_list = Map.to_list(symbols)

    Enum.filter(symbols, fn {_name, defn} -> defn.state == :known end)
    |> length()
  end

  def get_unknown_symbols(%ADotOut{} = aout) do
    Enum.filter(aout.symbols, fn {_name, defn} -> defn.state == :unknown end)
  end
end
