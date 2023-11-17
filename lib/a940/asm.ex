defmodule A940.Asm do
  require Record
  alias A940.SourceLine
  require SourceLine
  import Bitwise

  defstruct [:source, syms: %{}, assigns: %{}, ok: true]
  # source is a list of /A940.SourceLine sourceline/s.
  # where n is the line number, location is the word address for this line
  # and string is the source (trimmed)
  # loc is initial nil
  def run(args, parms) do
    # args: tuples like {:origin, ##}, {:start, ##}, {:out, "a-file"}
    # parms: list of input file names
    {args, parms}

    rv =
      %__MODULE__{}
      |> assigns(parms)
      |> read_source(args)
      |> analyze()
      |> assign_locations()
      |> set_addresses()
      |> create_output()

    rv |> dbg
  end

  def assigns(%__MODULE__{} = s, parm_list) when is_list(parm_list) and length(parm_list) == 3 do
    assigns =
      Enum.reduce(parm_list, %{}, fn {key, val} = _parm, acc -> add_assign(acc, key, val) end)

    %{s | assigns: assigns}
  end

  def read_source(%__MODULE__{} = s, [file_name] = _args) do
    {:ok, inhalt} = File.read(file_name)

    src =
      inhalt
      |> String.split("\n")
      |> Enum.map(&String.trim_trailing(&1))

    numbers = 1..length(src)

    src =
      Enum.zip(numbers, src)
      |> Enum.reduce([], fn {num, inhalt} = _line, acc ->
        [SourceLine.sourceline(text: inhalt, linenumber: num) | acc]
      end)
      |> Enum.reverse()

    %{s | source: src}
  end

  def analyze(%__MODULE__{source: src} = s) do
    om = A940.OpcodeMap.opcode_map()
    %{s | source: Enum.map(src, &analyze_one_line(&1, om))}
  end

  def assign_locations(%__MODULE__{} = s) do
    acc_src_lines = {[], Map.get(s.assigns, :org)}

    {new_src_lines, last_plus_1} =
      Enum.reduce(
        s.source,
        acc_src_lines,
        fn src_line, {source_lines, address} ->
          update_src_line_location(src_line, source_lines, address)
        end
      )

    # new_src_lines are in reverse order here...

    symbol_table =
      Enum.reduce(new_src_lines, %{}, fn src_line, symbol_table ->
        create_symbol_table_entry(src_line, symbol_table)
      end)

    cond do
      last_plus_1 <= Map.get(s.assigns, :start) -> {:error, "start address > actual end"}
      true -> nil
    end

    new_assigns = Map.put(s.assigns, :end, last_plus_1 - 1)

    %{s | syms: symbol_table, source: Enum.reverse(new_src_lines), assigns: new_assigns}
  end

  def set_addresses(%__MODULE__{source: src_lines, syms: symbol_table} = s) do
    new_source_lines =
      Enum.map(src_lines, fn src_line -> update_address_in_line(src_line, symbol_table) end)

    %{s | source: new_source_lines}
  end

  def update_address_in_line(src_line, symbol_table) do
    indirect_val = if SourceLine.sourceline(src_line, :indirect), do: 0o20000000, else: 0
    indexed_val = if SourceLine.sourceline(src_line, :indexed), do: 0o40000, else: 0
    mem_reference_mask = 0o37777
    shift_mask = if indirect_val > 0, do: 0o37777, else: 0o777
    {instruction_type, data} = SourceLine.sourceline(src_line, :inhalt)
    line_type = SourceLine.sourceline(src_line, :type)
    address_line_types = [:nolabelysaddr, :yslabelysaddr]
    no_change_types = [:no_addr, :string_data, :number_data, :reg_op, :error, nil]
    instruction_types_for_address = [:mem_addr, :shift_op, :reg_op_addr]

    address =
      cond do
        line_type in address_line_types and instruction_type in instruction_types_for_address ->
          evaluate_address(SourceLine.sourceline(src_line, :address), symbol_table)

        true ->
          0
      end

    new_data =
      cond do
        instruction_type == :mem_addr and line_type in address_line_types ->
          [hd(data) ||| (address &&& mem_reference_mask) ||| indirect_val ||| indexed_val]

        instruction_type == :shift_op and line_type in address_line_types and indirect_val == 0 ->
          [hd(data) ||| (address &&& shift_mask) ||| indexed_val]

        instruction_type == :shift_op and line_type in address_line_types and indirect_val != 0 ->
          [hd(data) ||| (address &&& mem_reference_mask) ||| indexed_val ||| indirect_val]

        instruction_type == :reg_op_addr and line_type in address_line_types and indirect_val == 0 and
            indexed_val == 0 ->
          [hd(data) ||| (address &&& mem_reference_mask)]

        instruction_type in no_change_types ->
          data

        true ->
          IO.puts("WTD?")
          src_line |> dbg
          [:illegal]
      end

    SourceLine.sourceline(src_line, inhalt: {instruction_type, new_data})
  end

  def create_output(%__MODULE__{} = s) do
    s |> create_binary_output |> create_listing_output()
  end

  def create_binary_output(%__MODULE__{assigns: assigns, source: src_lines} = s) do
    # make it binary
    {:ok, file} = File.open(Map.get(assigns, :out), [:write, :binary])

    [Map.get(assigns, :org), Map.get(assigns, :end), Map.get(assigns, :start)]
    |> binary_output_data(file)

    Enum.map(src_lines, &SourceLine.sourceline(&1, :inhalt))
    |> Enum.map(fn {_, data} -> binary_output_data(data, file) end)

    File.close(file)
    s
  end

  def binary_output_data(datalist, file) when is_list(datalist) do
    Enum.map(datalist, &binary_output_data(&1, file))
  end

  def binary_output_data(datum, file) when is_integer(datum) do
    <<a::8, b::8, c::8>> = <<datum::24>>
    IO.binwrite(file, [a, b, c])
  end

  def create_listing_output(%__MODULE__{source: src_lines} = s) do
    Enum.each(src_lines, &output_1_line_listing(&1))
    s
  end

  def output_1_line_listing(line) do
    # these fields
    # text: String.t()
    # label: String.t(),
    # opcode: String.t(),
    # address: String.t(),
    # indirect: Atom.t(),
    # indexed: Atom.t(),
    # location: Integer.t(),
    # inhalt: Tuple.t()
    {_, data_words} = SourceLine.sourceline(line, :inhalt)

    [
      octal_str(SourceLine.sourceline(line, :location), 5),
      " ",
      first_inhalt(data_words),
      " ",
      SourceLine.sourceline(line, :text)
    ]
    |> IO.puts()

    subsequent_inhalt(data_words, SourceLine.sourceline(line, :location)) |> IO.write()
  end

  def octal_str(num, width), do: Integer.to_string(num, 8) |> String.pad_leading(width, "0")

  def first_inhalt([]), do: String.duplicate(" ", 8)
  def first_inhalt(l), do: octal_str(hd(l), 8)

  def subsequent_inhalt([], _), do: []
  def subsequent_inhalt(l, _) when length(l) == 1, do: []

  def subsequent_inhalt([_ | t] = _l, loc) do
    locs = (loc + 1)..(loc + length(t))

    Enum.zip(locs, t)
    |> Enum.map(fn {loc, datum} -> [octal_str(loc, 5), " ", octal_str(datum, 8), "\n"] end)
  end

  def analyze_one_line(src_line, om) do
    l = SourceLine.sourceline(src_line, :text)

    if String.starts_with?(l, "*") or 0 == String.length(l) do
      SourceLine.sourceline(src_line, type: :comment, inhalt: {nil, []})
    else
      # returns the list of words created by this statement.
      no_label_no_addr =
        ~r/^[[:blank:]]+(?<opcode>[A-Za-z][[:alnum:]]*)(?<indirect>\*{0,1})[[:blank:]]*$/

      no_label_ys_addr =
        ~r/^[[:blank:]]+(?<opcode>[A-Za-z][[:alnum:]]*)(?<indirect>\*{0,1})[[:blank:]]+(?<address>.+?)(?<indexed>(,2){0,1})$/

      ys_label_no_addr =
        ~r/^(?<label>[A-Za-z][[:alnum:]]*)[[:blank:]]+(?<opcode>[A-Za-z][[:alnum:]]*)(?<indirect>\*{0,1})[[:blank:]]*$/

      ys_label_ys_addr =
        ~r/^(?<label>[A-Za-z][[:alnum:]]*)[[:blank:]]+(?<opcode>[A-Za-z][[:alnum:]]*)(?<indirect>\*{0,1})[[:blank:]]+(?<address>.+?)(?<indexed>(,2){0,1})$/

      patterns = [no_label_no_addr, no_label_ys_addr, ys_label_no_addr, ys_label_ys_addr]

      Enum.map(patterns, &Regex.match?(&1, l))
      |> parse_one(src_line, om, patterns)
    end
  end

  def add_assign(map, key, val) when is_atom(key) and is_map(map) do
    if key in [:org, :start, :out] do
      Map.put(map, key, val)
    else
      {:error, "illegal parameter"}
    end
  end

  def parse_one(match_vector, src_line, om, patterns) do
    {type, pattern_index} =
      cond do
        [true, false, false, false] == match_vector -> {:nolabelnoaddr, 0}
        [false, true, false, false] == match_vector -> {:nolabelysaddr, 1}
        [false, false, true, false] == match_vector -> {:yslabelnoaddr, 2}
        [false, false, false, true] == match_vector -> {:yslabelysaddr, 3}
      end

    {l, o, a, i, x} =
      parse_statement(Enum.at(patterns, pattern_index), SourceLine.sourceline(src_line, :text))

    data = match_opcode(o, a, om)

    SourceLine.sourceline(src_line,
      label: l,
      opcode: o,
      address: a,
      indirect: i,
      indexed: x,
      type: type,
      inhalt: data
    )
  end

  def parse_statement(pattern, stmt) do
    match_results = Regex.named_captures(pattern, stmt)

    {
      Map.get(match_results, "label", ""),
      Map.get(match_results, "opcode", ""),
      Map.get(match_results, "address", ""),
      Map.get(match_results, "indirect", "") != "",
      Map.get(match_results, "indexed", "") != ""
    }
  end

  def match_opcode(opcode, address, om) do
    {val, type} = Map.get(om, opcode, {nil, :error})

    cond do
      type in [:mem_addr, :reg_op_addr, :shift_op] and String.length(address) > 0 -> {type, [val]}
      type == :number_data and String.length(address) > 0 -> {type, data_value(address)}
      type in [:reg_op, :no_addr] -> {type, [val]}
      type == :string_data -> {:string_data, string_as_words(address)}
      true -> {:error, []}
    end
  end

  def data_value(a) do
    [
      cond do
        String.match?(a, ~r/([0-7]+B)|([0-9a-fA-f]+X)|([0-9]+)/) == false ->
          :error

        String.ends_with?(a, ["B", "b"]) ->
          a |> String.slice(0..(String.length(a) - 2)) |> String.to_integer(8)

        String.ends_with?(a, ["X", "x"]) ->
          a |> String.slice(0..(String.length(a) - 2)) |> String.to_integer(16)

        true ->
          String.to_integer(a, 10)
      end
    ]
  end

  def string_as_words(address) do
    # convert real ASCII into SDS 8-bit.
    convert_to_940_codes = fn a -> if a >= 0o40, do: a - 0o40, else: a + 0o140 end
    # turn a list of 3 bytes (0<=integers<256) into a 24 bit word
    pack_in_word = fn [a, b, c] -> (a * 256 + b) * 256 + c end
    captures = Regex.named_captures(~r/^"(?<string>[^"]+)"$/, address)

    s_list =
      Map.get(captures, "string")
      |> convert_escapes()
      |> String.to_charlist()
      |> Enum.map(fn x -> convert_to_940_codes.(x) end)

    cond do
      rem(length(s_list), 3) == 0 -> s_list
      rem(length(s_list), 3) == 1 -> s_list ++ [0, 0]
      rem(length(s_list), 3) == 2 -> s_list ++ [0]
    end
    |> Enum.chunk_every(3, 3)
    |> Enum.map(fn three -> pack_in_word.(three) end)
  end

  def convert_escapes(s) do
    # the .* is greedy, so must convert from right to left
    v = Regex.named_captures(~r/^(?<initial>.*)\\(?<code>[0-3][0-7]{2})(?<final>.*)$/, s)

    cond do
      v == nil ->
        s

      true ->
        # initial part may have \nnn codes
        (Map.get(v, "initial") |> convert_escapes()) <>
          List.to_string([String.to_integer(Map.get(v, "code"), 8)]) <>
          Map.get(v, "final")
    end
  end

  def update_src_line_location(src_line, source_lines, address) do
    {_type, data} = SourceLine.sourceline(src_line, :inhalt)
    new_src_line = SourceLine.sourceline(src_line, location: address)
    new_source_lines = [new_src_line | source_lines]
    new_address = address + length(data)
    {new_source_lines, new_address}
  end

  def create_symbol_table_entry(src_line, symbol_table) do
    type = SourceLine.sourceline(src_line, :type)
    location = SourceLine.sourceline(src_line, :location)

    cond do
      type == :yslabelnoaddr or type == :yslabelysaddr ->
        Map.put(symbol_table, SourceLine.sourceline(src_line, :label), location)

      true ->
        symbol_table
    end
  end

  def evaluate_address(address_field, symbol_table) do
    # eventually use [{:abacus, "~> 0.4.2"}]
    value_if_number = hd(data_value(address_field))
    value_if_symbol = Map.get(symbol_table, address_field)

    cond do
      :error != value_if_number -> value_if_number
      nil != value_if_symbol -> value_if_symbol
      true -> {:error, "cannot evaluate '#{address_field}'"}
    end
  end
end
