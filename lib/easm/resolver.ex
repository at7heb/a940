defmodule Easm.Resolver do
  alias Easm.Symbol
  alias Easm.ADotOut
  alias Easm.Expression

  @doc """
  returns {name, %symbol{}} for each expression symbol in aout's memory
  """
  def addresses_needing_resolution(%ADotOut{} = aout) do
    aout.memory
    |> Enum.filter(fn mem ->
      is_binary(mem.symbol_name) and String.starts_with?(mem.symbol_name, "E_")
    end)
    |> Enum.map(fn mem -> mem.symbol_name end)
    |> Enum.map(fn name -> {name, Map.get(aout.symbols, name)} end)
  end

  def try_resolving(%ADotOut{} = aout) do
  end

  def try_resolving_one(%Symbol{} = symbol, %{} = symbols) do
    tokens = symbol.definition
    # nonsense value
    star = {16383, 5}
    _value = Expression.start_eval(tokens, star, symbols) |> dbg
  end
end
