defmodule A940.Asm do
  defstruct [:source, :obj, :syms, assigns: %{}, ok: true, line_count: 0]
  # source is a map line_number -> {location, string}
  # where n is the line number, location is the word address for this line
  # and string is the source (trimmed)
  # loc is initial nil
  def run(args, parms) do
    # args: tuples like {:origin, ##}, {:start, ##}, {:out, "a-file"}
    # parms: list of input file names
    {args, parms} |> dbg

    s =
      %__MODULE__{}
      |> assigns(parms)
      |> read_source(args)
      |> build_symbol_table()

    s |> dbg
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
      |> Enum.map(&{nil, String.trim_trailing(&1)})

    numbers = 1..length(src)
    src1 = Enum.zip(numbers, src)
    src2 = Enum.reduce(src1, %{}, fn {num, inhalt} = _line, acc -> Map.put(acc, num, inhalt) end)
    %{s | source: src2, line_count: length(src)}
  end

  def build_symbol_table(%__MODULE__{source: src, line_count: lc} = s) do
    opcode_map = A940.OpcodeMap.opcode_map()
    code1 = pass1_0(src, lc, Map.get(s.assigns, :start), opcode_map)
    symtab = pass1_5(src, code1)
  end

  def add_assign(map, key, val) when is_atom(key) and is_map(map) do
    if key in [:org, :start, :out] do
      Map.put(map, key, val)
    else
      {:error, "illegal parameter"}
    end
  end

  def pass1_0(src, lc, org, om) do
    # returns map of line number => {address, content}
    # content is usually [integer]. In case of STRING op, though, it
    # might be [int0, int1, ..., intn]
    # in the case of a pseudo op that generates no code (DEFERRED),
    # it can be [], so the location can be incremented by
    # length(content)
    data_list = Enum.map(1..lc, &decode_for_data(&1, Map.get(src, &1), om)) |> dbg
    # data_list is a list of lists. hd(data_list) corresponds to
    # source line 1 and is the data for line 1
    # must start addresses at org, then for lines 2..last
    # address of line is address of line-1 + length(data of line-1)

    # must

    rv =
      Enum.reduce(
        Enum.zip(2..lc, tl(data_list)),
        %{1 => {org, hd(data_list)}},
        fn {line_number, data} = _dl, map ->
          {prev_loc, prev_data} = Map.get(map, line_number - 1)
          Map.put(map, line_number, {prev_loc + length(prev_data), data})
        end
      )
  end

  def pass1_5(src, code) do
    {:error, "not written"}
  end

  def decode_for_data(_source_line_number, {_data, line} = _source_line, om) do
    if String.starts_with?(line, "*") or 0 == String.length(line) do
      0
    else
      # returns the list of words created by this statement.
      no_label_no_addr = ~r/^[[:blank:]]+(?<opcode>[A-Za-z][[:alnum:]]*)[[:blank:]]*$/

      no_label_ys_addr =
        ~r/^[[:blank:]]+(?<opcode>[A-Za-z][[:alnum:]]*)[[:blank:]]+(?<address>.+)$/

      ys_label_no_addr =
        ~r/^(?<label>[A-Za-z][[:alnum:]]*)[[:blank:]]+(?<opcode>[A-Za-z][[:alnum:]]*)[[:blank:]]*$/

      ys_label_ys_addr =
        ~r/^(?<label>[A-Za-z][[:alnum:]]*)[[:blank:]]+(?<opcode>[A-Za-z][[:alnum:]]*)[[:blank:]]+(?<address>.+)$/

      patterns = [no_label_no_addr, no_label_ys_addr, ys_label_no_addr, ys_label_ys_addr]

      Enum.map(patterns, &Regex.match?(&1, line))
      |> decode_for_data(line, om, patterns)
      |> dbg

      [1]
    end
  end

  # no label, no address
  def decode_for_data([true, false, false, false], stmt, om, patterns) do
    {_label, opcode, _address} = parse_statement(Enum.at(patterns, 0), stmt)
    match_opcode(opcode, om)
  end

  # no label, yes address
  def decode_for_data([false, true, false, false], stmt, om, patterns) do
    {_label, opcode, address} = parse_statement(Enum.at(patterns, 1), stmt)
    match_opcode(opcode, address, om)
  end

  # yes label, no address
  def decode_for_data([false, false, true, false], stmt, om, patterns) do
    {_label, opcode, _address} = parse_statement(Enum.at(patterns, 2), stmt)
    match_opcode(opcode, om)
  end

  # yes label, yes address
  def decode_for_data([false, false, false, true], stmt, om, patterns) do
    {_label, opcode, address} = parse_statement(Enum.at(patterns, 3), stmt)
    match_opcode(opcode, address, om)
  end

  def parse_statement(pattern, stmt) do
    match_results = Regex.named_captures(pattern, stmt)

    {
      Map.get(match_results, "label"),
      Map.get(match_results, "opcode"),
      Map.get(match_results, "address")
    }
  end

  def match_opcode(opcode, om) do
    {val, type} = Map.get(om, opcode)

    cond do
      # statement takes one word
      type in [:reg_op, :no_addr] -> 1
      true -> {:error, "opcode #{opcode} requires address"}
    end
  end

  def match_opcode(opcode, address, om) do
    {val, type} = Map.get(om, opcode) |> dbg

    cond do
      type in [:number_data, :mem_addr, :reg_op_addr, :shift_op] -> 1
      type == :string_data -> string_length_in_words(address)
      true -> {:error, "opcode #{opcode} has illegal address"}
    end
  end

  def string_length_in_words(address) do
    v = Regex.named_captures(~r/^"(?<string>[^"]+)"$/, address)
    s = Map.get(v, "string")
    s1 = convert_escapes(s)
    div(2 + String.length(s1), 3)
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

  def xxx do
  end
end
