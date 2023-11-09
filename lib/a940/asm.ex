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
    s = (
      %__MODULE__{}
      |> assigns(parms)
      |> read_source(args)
      |> build_symbol_table()
    )
    s |> dbg
  end

  def assigns(%__MODULE__{} = s, parm_list) when is_list(parm_list) and length(parm_list) == 3 do
    assigns = Enum.reduce(parm_list, %{}, fn {key, val} = _parm, acc -> add_assign(acc, key, val) end)
    %{s | assigns: assigns}
  end

  def read_source(%__MODULE__{} = s, [file_name] = _args) do
    {:ok, inhalt} = File.read(file_name)
    src = (
      inhalt
      |> String.split("\n")
      |> Enum.map(&({nil, String.trim_trailing(&1)}))
    )
    numbers = 1..length(src)
    src1 = Enum.zip(numbers, src)
    src2 = Enum.reduce(src1, %{}, fn {num, inhalt} = _line, acc -> Map.put(acc, num, inhalt) end)
    %{s | source: src2, linecount: length(src)}
  end

  def build_symbol_table(%__MODULE__{source: src, line_count: lc} = s) do
    opcode_map = A940.OpcodeMap.opcode_map()
    code1 = pass1_0(src, lc, Map.get(s.assigns, :start), opcode_map)
    symtab = pass1_5(src, code1)
  end

  def add_assign(map, key, val) when is_atom(key) and is_map(map) do
    if key in [:org, :start, :out] do Map.put(map, key, val) else {:error, "illegal parameter"} end
  end

  def pass1_0(src, lc, org, om) do
    # returns map of line number => {address, content}
    # content is usually [integer]. In case of STRING op, though, it
    # might be [int0, int1, ..., intn]
    # in the case of a pseudo op that generates no code (DEFERRED),
    # it can be [], so the location can be incremented by
    # length(content)
    data_list = Enum.map(1..lc, &(decode_for_data(&1, Map.get(src, &1), om)))
    # data_list is a list of lists. hd(data_list) corresponds to
    # source line 1 and is the data for line 1
    # must start addresses at org, then for lines 2..last
    # address of line is address of line-1 + length(data of line-1)

    # must


    rv = Enum.reduce(Enum.zip(2..lc, tl(data_list)),
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

  def decode_for_data(source_line_number, source_line, om) do
    # puts in map source_line_number =>
  end

  def xxx do

  end
end
