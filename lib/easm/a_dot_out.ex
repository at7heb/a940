defmodule Easm.ADotOut do
  alias Easm.Symbol
  alias Easm.ADotOut

  defstruct memory: [],
            symbols: %{},
            lines: %{},
            line_count: 0,
            if_status: [true],
            # or :absolute
            relocation_reference: :relocatable,
            absolute_location: 0,
            relocatable_location: 0,
            needs: [:ident, :end],
            # the label defined in current statement;
            label: "THELABEL",
            # line_ok: true,
            file_ok: true,
            listing: [],
            # add {:psuedo, <the pseudo atom>}
            flags: []

  # each memory has {:relocatable, address, content} or {:absolute, address, content}
  # flags can have :absolute_location, :relative_location, :export_symbol

  def new(), do: %ADotOut{}

  def increment_current_location(
        %ADotOut{absolute_location: absolute_location, relocatable_location: relocatable_location} =
          aout,
        increment \\ 1
      ) do
    case aout.relocation_reference do
      :absolute -> %{aout | absolute_location: absolute_location + increment}
      :relocatable -> %{aout | relocatable_location: relocatable_location + increment}
      _ -> aout
    end
  end

  def add_symbol(%ADotOut{} = aout, %Symbol{} = symbol) do
    aout
  end
end
