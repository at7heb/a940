defmodule Easm.Symbol do
  alias Easm.ADotOut
  alias Easm.Lexer

  defstruct state: false,
            value: [1_000_000_000],
            relocatable: true,
            relocation: 0,
            definition: [],
            exported: false

  # type should include :exported and :imported
  # store in a map, and then the symbol is redundant
  # For code like "A EQU B1END-B1BEG, definition will have the tokens [{:symbol, "B1END},{:operator, "-"},{:symbol, "B1BEG"}]
  # It will have a value after B1END and B1BEG are known
  #
  # For code like "A EQU 500", :state will be :known
  # :state is :unknown, then :defined, then :known.
  # :state must be :defined or :known when the aout file is delivered to the link editor.
  # for expressions, :state will :defined and value will be nil.
  # later, :state will be :known and value will be set
  # if one of the symbols is external, the expression will go into a.out
  # for A in A EQU B, state will be [{:symbol, "B"}]

  alias Easm.Symbol

  def symbol(), do: %Easm.Symbol{}

  def symbol(%ADotOut{} = _aout), do: symbol()

  def symbol_absolute(value),
    do: %Easm.Symbol{state: :known, value: value, relocatable: false, relocation: 0}

  def symbol_relative(value),
    do: %Easm.Symbol{state: :known, value: value, relocatable: true, relocation: 1}

  def symbol_here(%ADotOut{} = aout) do
    {location, relocatable?} = Easm.Memory.get_location(aout)
    %Symbol{value: location, state: :known, relocatable: relocatable?}
  end

  def symbol_by_expression(
        %ADotOut{} = aout,
        [{:askterisk, _}, {:operator, "+"}, {:number, number_text}] = tokens
      ) do
    symbol_relative(aout, 1, Lexer.number_value(number_text), tokens)
  end

  def symbol_by_expression(
        %ADotOut{} = aout,
        [{:askterisk, _}, {:operator, "-"}, {:number, number_text}] = tokens
      ) do
    symbol_relative(aout, -1, Lexer.number_value(number_text), tokens)
  end

  def symbol_by_expression(
        %ADotOut{} = _aout,
        [{:askterisk, _}, {:operator, "-"}, {:askterisk, _}] = tokens
      ) do
    %Symbol{value: 0, state: :known, relocatable: false, definition: tokens}
  end

  def symbol_relative(%ADotOut{} = aout, mult, offset, tokens)
      when is_integer(mult) and is_integer(offset) and is_list(tokens) do
    {location, relocatable?} = Easm.Memory.get_location(aout)

    %Symbol{
      value: location + mult * offset,
      state: :known,
      relocatable: relocatable?,
      definition: tokens
    }
  end

  def new(symbol_value \\ nil, tokens \\ [], state \\ :unknown) do
    %Symbol{value: symbol_value, state: state, definition: tokens, relocatable: false}
  end

  def generate_name(:literal), do: "L_" <> Uniq.UUID.uuid1()
  def generate_name(:expression), do: "E_" <> Uniq.UUID.uuid1()
end
