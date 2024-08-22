defmodule Easm.ADotOut do
  alias Easm.Symbol
  alias Easm.ADotOut
  alias Easm.ListingLine
  alias Easm.Memory

  import Bitwise

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

  @rch_mask 0o1777
  @shift_mask 0o3777
  @mem_mask 0o37777

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
        # {"adding symbol", symbol_name, symbol} |> dbg
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
    # {symbol_name, new_symbol} |> dbg
    %{aout | symbols: new_symbols}
  end

  def clean_for_new_statement(%ADotOut{} = aout) do
    %{aout | label: ""}
  end

  @doc """
  update addresses in aout.
  """
  def update_addresses(%ADotOut{} = aout) do
    # octal_list(aout.memory) |> dbg
    new_memory = update_addresses(aout.memory, aout.symbols)
    # octal_list(aout.memory) |> dbg
    %{aout | memory: new_memory}
  end

  @doc """
  update addresses with just memory and symbols
  """
  def update_addresses(memory, symbols) when is_list(memory) and is_map(symbols) do
    Enum.map(memory, fn mem -> maybe_update_address(mem, symbols) end)
  end

  @doc """
  for a single instruction, may update address, but only if
  the instruction has an address
  """
  def maybe_update_address(%Memory{} = mem, symbols) do
    cond do
      # nothing to do
      mem.symbol_name == "" -> mem
      true -> update_address(mem, Map.get(symbols, mem.symbol_name))
    end
  end

  @doc """
  if the symbol value is :known, can update the address.
  This handles register change, shift, and memory address types.
  :shift_addr, :rch_addr, or :mem_addr
  """
  def update_address(%Memory{} = mem, %Symbol{state: :unknown} = _symbol), do: mem
  def update_address(%Memory{} = mem, %Symbol{state: :defined} = _symbol), do: mem

  def update_address(
        %Memory{address_field_type: :shift_addr} = mem,
        %Symbol{state: :known, relocation: 0} = symbol
      ),
      do: update_address(mem, symbol, @shift_mask)

  def update_address(
        %Memory{address_field_type: :rch_addr} = mem,
        %Symbol{state: :known, relocation: 0} = symbol
      ),
      do: update_address(mem, symbol, @rch_mask)

  def update_address(
        %Memory{address_field_type: :mem_addr} = mem,
        %Symbol{state: :known} = symbol
      ),
      do: update_address(mem, symbol, @mem_mask)

  def update_address(%Memory{} = mem, %Symbol{value: value} = symbol, mask)
      when is_integer(mask) and is_integer(value) do
    new_content = (mem.content &&& bnot(mask)) ||| (value &&& mask)
    {"update address", mem.content, mask, value, new_content} |> dbg
    %{mem | content: new_content, address_relocation: symbol.relocation, symbol_name: ""}
  end

  def update_address(%Memory{} = mem, %Symbol{value: value} = _symbol, mask)
      when is_integer(mask) and is_tuple(value) do
    {new_addr, new_relocation} = value
    new_content = (mem.content &&& bnot(mask)) ||| (new_addr &&& mask)
    # {"update address", mem.content, mask, new_addr, new_content} |> dbg

    %{mem | content: new_content, address_relocation: new_relocation, symbol_name: ""}
  end

  def update_listing_content(%ADotOut{} = aout) do
    mem_map = make_memory_map(aout.memory)

    new_listing =
      Enum.map(aout.listing, fn one_line -> update_one_line_listing(one_line, mem_map) end)

    %{aout | listing: new_listing}
  end

  def list(%ADotOut{listing: listing} = aout) do
    Enum.sort(listing, fn l1, l2 ->
      l1.relocation <= l2.relocation and l1.location <= l2.location
    end)
    |> Enum.each(fn l -> IO.puts(ListingLine.to_string(l)) end)

    aout
  end

  # defp octal_list(memory) do
  #   Enum.sort(memory, &(&1.location <= &2.location))
  #   |> Enum.map(fn mem ->
  #     Integer.to_string(mem.location, 8) <>
  #       ": " <>
  #       Integer.to_string(mem.address_relocation, 8) <> " " <> Integer.to_string(mem.content, 8)
  #   end)
  # end

  defp make_memory_map(memory) when is_list(memory) do
    Enum.reduce(memory, %{}, fn mem, map ->
      Map.put(map, {mem.instruction_relocation, mem.location}, mem.content)
    end)
  end

  defp update_one_line_listing(
         %ListingLine{location: location, relocation: relocation} = one_line,
         %{} = mem_map
       ) do
    # defstruct location: 0, relocation: 0, content: 0, text: ""
    new_content = Map.get(mem_map, {relocation, location}, 0o77777777)

    if {relocation, location} != new_content do
      # {"update one line listing", new_content, {relocation, location}} |> dbg
    end

    ListingLine.update_content(one_line, new_content)
  end
end
