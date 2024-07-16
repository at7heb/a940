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
            label: "",
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

  def get_current_location(%ADotOut{} = aout) do
    case aout.relocation_reference do
      :absolute -> {aout.absolute_location, 0}
      :relocatable -> {aout.relocatable_location, 1}
      _ -> {0, 0}
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

  def handle_address_symbol(%ADotOut{} = aout, _name, nil), do: aout

  def handle_address_symbol(%ADotOut{} = _aout, name, value) do
    {"name and value do not compute", name, value} |> dbg
    raise "symbol name and value do not compute"
  end

  def add_symbol(%ADotOut{symbols: symbols} = aout, symbol_name, %Symbol{} = symbol)
      when is_binary(symbol_name) do
    # this should be private to guarantee that symbol_name isn't in the map yet!
    %{aout | symbols: Map.put(symbols, symbol_name, symbol)}
  end

  def update_label_in_symbol_table(%ADotOut{label: ""} = aout), do: aout
  def update_label_in_symbol_table(%ADotOut{label: nil} = aout), do: aout

  def update_label_in_symbol_table(%ADotOut{symbols: symbols, label: symbol_name} = aout) do
    {symbols, symbol_name} |> dbg

    {location, relocatable, relocation} =
      cond do
        aout.relocation_reference == :relocatable -> {aout.relocatable_location, true, 1}
        true -> {aout.absolute_location, false, 0}
      end

    symbol = Map.get(symbols, symbol_name)

    new_symbol = %{
      symbol
      | value: location,
        relocatable: relocatable,
        relocation: relocation,
        state: :known
    }

    new_symbols = Map.put(aout.symbols, symbol_name, new_symbol)
    new_symbols |> dbg
    %{aout | symbols: new_symbols}
  end

  def clean_for_new_statement(%ADotOut{} = aout) do
    %{aout | label: ""}
  end
end
