defmodule Easm.ADotOut do
  defstruct memory: [],
            symbols: %{},
            if_status: [true],
            relocation_reference: :absolute,
            absolute_location: 0,
            relocatable_location: 0,
            needs: [:ident, :end],
            state: :beginning_of_line,
            label: "THELABEL",
            flags: []

  # each memory has {:relocatable, address, content} or {:absolute, address, content}
  # flags can have :absolute_location, :relative_location, :export_symbol
end
