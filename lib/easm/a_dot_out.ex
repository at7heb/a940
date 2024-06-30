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

  def handle_address_symbol(%ADotOut{} = aout, "", _), do: aout

  def handle_address_symbol(%ADotOut{symbols: symbols} = aout, symbol_name, %Symbol{} = symbol) do
    cond do
      Map.get(symbols, symbol_name) == nil ->
        add_symbol(aout, symbol_name, symbol)

      true ->
        aout

        # if already in the symbol table, could be previous LOOP1 STA A,2 or else STRINCR EQU 3; ... EAX STRINCR
    end
  end

  def handle_address_symbol(%ADotOut{} = aout, name, value) do
    {"name #{name} and value #{value} do not compute"} |> dbg
    aout
  end

  def add_symbol(%ADotOut{symbols: symbols} = aout, symbol_name, %Symbol{} = symbol)
      when is_binary(symbol_name) do
    # this should be private to guarantee that symbol_name isn't in the map yet!
    %{aout | symbols: Map.put(symbols, symbol_name, symbol)}
  end
end
