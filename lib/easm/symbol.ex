defmodule Easm.Symbol do
  defstruct known: false, value: [1_000_000_000], type: :unknown, relocatable: true
  # type should include :exported and :imported
  # store in a map, and then the symbol is redundant

  alias Easm.Symbol

  def symbol(), do: %Easm.Symbol{}

  def symbol(%Easm.ADotOut{} = aout) do
    {location, relocatable?} = Easm.Memory.get_location(aout)
    %Symbol{value: location, known: true, relocatable: relocatable?}
  end
end
