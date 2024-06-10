defmodule Easm.Symbol do
  defstruct known: false, value: [1], type: :unknown, relocatable: true
  # type should include :exported and :imported
  # store in a map, and then the symbol is redundant

  alias Easm.Symbol

  def symbol(), do: %Easm.Symbol{}

  def symbol(%Easm.ADotOut{} = aout) do
    cond do
      :absolute_location in aout.flags ->
        %Symbol{value: aout.absolute_location, known: true, relocatable: false}

      :relative_location in aout.flags ->
        %Symbol{value: aout.relocatable_location, known: true, relocatable: true}

      # one or the other of these flags normally set, but at "2BAS IDENT" time, not...
      true ->
        %Symbol{value: 0, known: false}
    end
  end
end
