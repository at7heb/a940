defmodule A940.Asm do
  require Record
  alias A940.SourceLine
  require SourceLine

  defstruct [:source, :syms, assigns: %{}, ok: true, line_count: 0]
  # source is a list of /A940.SourceLine sourceline/s.
  # where n is the line number, location is the word address for this line
  # and string is the source (trimmed)
  # loc is initial nil
  def run(args, parms) do
    # args: tuples like {:origin, ##}, {:start, ##}, {:out, "a-file"}
    # parms: list of input file names
    {args, parms} |> dbg

    %__MODULE__{}
    |> assigns(parms)
    |> read_source(args)
    |> analyze()
    |> assign_locations()
    |> set_addresses()
    |> create_output()
    |> dbg
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
      |> Enum.map(&(String.trim_trailing(&1)))

    numbers = 1..length(src)

    src =
      Enum.zip(numbers, src)
      |> Enum.reduce([], fn {num, inhalt} = _line, acc -> [{SourceLine, text: inhalt, linenumber: num} | acc] end)
      |> Enum.reverse()

    %{s | source: src, line_count: length(src)}
  end

  def analyze(%__MODULE__{source: src} = s) do
    om = A940.OpcodeMap.opcode_map()
    %{s | source: Enum.map(src, &(analyze_one_line(&1, om)))}
  end

  def assign_locations(%__MODULE__{} = s) do
    s
  end

  def set_addresses(%__MODULE__{} = s) do
    s
  end

  def create_output(%__MODULE__{} = s) do
    s
  end

  def analyze_one_line(src_line, om) do
    l = SourceLine.sourceline(src_line, :text)
    if String.starts_with?(l, "*") or 0 == String.length(l) do
      SourceLine.sourceline(src_line, type: :comment)
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

      Enum.map(patterns, &Regex.match?(&1, l))
      |> parse_one(src_line, om, patterns)
      |> dbg
    end
  end

  # def build_symbol_table(%__MODULE__{source: src, line_count: lc} = s) do
  #   opcode_map = A940.OpcodeMap.opcode_map()
  #   code1 = pass1_0(src, lc, Map.get(s.assigns, :start), opcode_map)
  #   _symtab = pass1_5(src, code1)
  # end

  def add_assign(map, key, val) when is_atom(key) and is_map(map) do
    if key in [:org, :start, :out] do
      Map.put(map, key, val)
    else
      {:error, "illegal parameter"}
    end
  end

  # def pass1_0(src, lc, org, om) do
  #   # returns map of line number => {address, content}
  #   # content is usually [integer]. In case of STRING op, though, it
  #   # might be [int0, int1, ..., intn]
  #   # in the case of a pseudo op that generates no code (DEFERRED),
  #   # it can be [], so the location can be incremented by
  #   # length(content)
  #   data_list = Enum.map(1..lc, &decode_for_data(&1, Map.get(src, &1), om)) |> dbg
  #   # data_list is a list of lists. hd(data_list) corresponds to
  #   # source line 1 and is the data for line 1
  #   # must start addresses at org, then for lines 2..last
  #   # address of line is address of line-1 + length(data of line-1)

  #   # must

  #   _rv =
  #     Enum.reduce(
  #       Enum.zip(2..lc, tl(data_list)),
  #       %{1 => {org, hd(data_list)}},
  #       fn {line_number, data} = _dl, map ->
  #         {prev_loc, prev_data} = Map.get(map, line_number - 1)
  #         Map.put(map, line_number, {prev_loc + length(prev_data), data})
  #       end
  #     )
  # end

  # def pass1_5(_src, _code) do
  #   {:error, "not written"}
  # end

  # def decode_for_data(sl, om) do
  #   if String.starts_with?(line, "*") or 0 == String.length(line) do
  #     0
  #   else
  #     # returns the list of words created by this statement.
  #     no_label_no_addr = ~r/^[[:blank:]]+(?<opcode>[A-Za-z][[:alnum:]]*)[[:blank:]]*$/

  #     no_label_ys_addr =
  #       ~r/^[[:blank:]]+(?<opcode>[A-Za-z][[:alnum:]]*)[[:blank:]]+(?<address>.+)$/

  #     ys_label_no_addr =
  #       ~r/^(?<label>[A-Za-z][[:alnum:]]*)[[:blank:]]+(?<opcode>[A-Za-z][[:alnum:]]*)[[:blank:]]*$/

  #     ys_label_ys_addr =
  #       ~r/^(?<label>[A-Za-z][[:alnum:]]*)[[:blank:]]+(?<opcode>[A-Za-z][[:alnum:]]*)[[:blank:]]+(?<address>.+)$/

  #     patterns = [no_label_no_addr, no_label_ys_addr, ys_label_no_addr, ys_label_ys_addr]

  #     Enum.map(patterns, &Regex.match?(&1, line))
  #     |> decode_for_data(line, om, patterns)
  #     |> dbg

  #     [1]
  #   end
  # end

  def parse_one(match_vector, src_line, om, patterns) do
    {type, pattern_index} =
      cond do
        [true, false, false, false] == match_vector -> {:nolabelnoaddr, 0}
        [false, true, false, false] == match_vector -> {:nolabelysaddr, 1}
        [false, false, true, false] == match_vector -> {:yslabelnoaddr, 2}
        [false, false, false, true] == match_vector -> {:yslabelysaddr, 3}
      end
      {l, o, a} = parse_statement(Enum.at(patterns, pattern_index), SourceLine.sourceline(src_line, :text))
      data = match_opcode(o, a, om)
      SourceLine.sourceline(src_line, label: l, opcode: o, address: a, type: type, inhalt: data)
  end

  def parse_statement(pattern, stmt) do
    match_results = Regex.named_captures(pattern, stmt)

    {
      Map.get(match_results, "label", ""),
      Map.get(match_results, "opcode", ""),
      Map.get(match_results, "address", "")
    }
  end

  def match_opcode(opcode, om) do
    {_val, type} = Map.get(om, opcode)

    cond do
      # statement takes one word
      type in [:reg_op, :no_addr] -> 1
      true -> {:error, "opcode #{opcode} requires address"}
    end
  end

  def match_opcode(opcode, address, om) do
    {val, type} = Map.get(om, opcode) |> dbg

    cond do
      (type in [:mem_addr, :reg_op_addr, :shift_op]) and (String.length(address) > 0) -> {type, [val]}
      (type == :number_data) and (String.length(address) > 0) -> {type, data_value(address)}
      type in [:reg_op, :no_addr] -> {type, [val]}
      type == :string_data -> {:string_data, string_in_words(address)}
      true -> {:error, [0]}
    end
  end

  def data_value(a) do
    cond do
      String.match?(a,~r/([0-7]+B)|([0-9a-fA-f]+X)|([0-9]+)/) == false -> -2
      String.ends_with?(a, ["B", "b"]) -> a |> String.slice(0..String.length(a)-1) |> String.to_integer(8)
      String.ends_with?(a, ["X", "x"]) -> a |> String.slice(0..String.length(a)-1) |> String.to_integer(16)
      true -> String.to_integer(a, 10)
    end
  end

  def string_in_words(address) do
    cvt = fn a -> if a >= 0o40, do: a - 0o40, else: a + 0o140 end
    mk_word = fn [a, b, c] -> ((a * 256) + b) * 256 + c end
    v = Regex.named_captures(~r/^"(?<string>[^"]+)"$/, address)
    s_list = Map.get(v, "string") |> convert_escapes() |> String.to_charlist() |> Enum.map(fn x -> cvt.(x) end)
    (cond do
      rem(length(s_list), 3) == 0 -> s_list
      rem(length(s_list), 3) == 1 -> s_list ++ [0, 0]
      rem(length(s_list), 3) == 2 -> s_list ++ [0]
    end)
    |> Enum.chunk_every(3, 3) |> Enum.map(fn three -> mk_word.(three) end )
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
