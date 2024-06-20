defmodule Easm.ADotOut do
  defstruct memory: [],
            symbols: %{},
            lines: %{},
            line_count: 0,
            if_status: [true],
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
end
