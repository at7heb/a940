defmodule Easm.Ops do
  alias Easm.ADotOut
  alias Easm.LexicalLine
  alias Easm.Memory
  alias Easm.Symbol
  alias Easm.Assembly
  alias Easm.Pseudos
  alias Easm.Address

  import Bitwise

  def handle_operator_part(%ADotOut{file_ok: false} = aout) do
    aout
  end

  # cases
  # operator
  # operator asterisk
  def handle_operator_part(%ADotOut{lines: lines} = aout) do
    cond do
      Assembly.has_flag?(aout, :done) ->
        aout

      true ->
        current_line = Map.get(lines, :current_line)

        handle_operator_part(
          aout,
          Map.get(lines, current_line)
        )
    end
  end

  def handle_operator_part(
        %ADotOut{} = aout,
        %LexicalLine{operation_tokens: op_tokens} = lex_line
      ) do
    cond do
      Assembly.has_flag?(aout, :done) or op_tokens == [] ->
        aout

      true ->
        handle_operator_part_ext(aout, lex_line)
    end
  end

  def handle_operator_part_ext(
        %ADotOut{} = aout,
        %LexicalLine{operation_tokens: op_tokens} = lex_line
      ) do
    {op0, op1} = {hd(op_tokens), Enum.at(op_tokens, 1)}

    {:symbol, op} = op0
    info_pseudo = Pseudos.pseudo_op_lookup(op)
    is_op = op_lookup(op)
    is_indirect = op_indirect(op1)

    {new_aout, okay?} =
      cond do
        info_pseudo != :not_pseudo and is_indirect == false ->
          {Pseudos.handle_pseudo(aout, lex_line, info_pseudo), true}

        is_op != :not_op ->
          {_, operator, address_type} = is_op
          {handle_op(aout, lex_line, operator, address_type, is_indirect), true}

        true ->
          {aout, false}
      end

    # {tokens, is_pseudo, is_op}
    Assembly.finish_part(new_aout, okay?)
  end

  @indirect 0o40000
  @index 0o20000000

  def misc_ops() do
    %{indirect: 0o40000, index: 0o20000000}
  end

  def index_bit(indexed?) when is_boolean(indexed?) do
    case indexed? do
      true -> @index
      false -> 0
    end
  end

  def index_bit(index_info) when is_atom(index_info) do
    case index_info do
      :indexed_yes -> @index
      :indexed_no -> 0
    end
  end

  def op_lookup(op) when is_binary(op) do
    op_info = Map.get(opcode_map(), op)

    cond do
      op_info == nil ->
        :not_op

      true ->
        {op_value, address_type} = op_info
        {:ok, op_value, address_type}
    end
  end

  # handle_op(aout, lex_line, operator, address_type, is_indirect)

  def handle_op(%ADotOut{} = aout, %LexicalLine{} = _ll, op_value, :no_addr, _indirect?) do
    # handle the op_value; put it in the memory.
    {current_location, relocation} = Memory.get_location(aout)

    memory_entry =
      Memory.memory(
        0,
        current_location,
        relocation,
        op_value,
        "",
        :no_addr
      )

    %{aout | memory: [memory_entry | aout.memory]}
    |> ADotOut.update_label_in_symbol_table()
    |> ADotOut.increment_current_location()

    # can add symbol, indirect, or indexed to hd(aout.memory).
  end

  def handle_op(
        %ADotOut{} = aout,
        %LexicalLine{} = _ll,
        op_value,
        :mem_addr,
        indirect?
      ) do
    # handle the op_value; put it in the memory.
    {current_location, instruction_relocation} = Memory.get_location(aout)

    {index_info, type, address_definition} = Address.get_address(aout)
    # {index_info, type, address_definition} |> dbg

    {new_op_value, relocation, symbol_name, symbol} =
      cond do
        type == :value ->
          {address_value, address_relocation} = address_definition

          {op_value ||| (address_value &&& 0o37777) ||| index_bit(index_info) |||
             indirect_bit(indirect?), address_relocation, "", nil}

        # ||| index_bit(indexed?)
        type == :expression ->
          name = Symbol.generate_name(:expression)

          {op_value ||| index_bit(index_info) ||| indirect_bit(indirect?), 0, name,
           address_definition}

        # literals must not be indexed
        # indirect with literal is kinda weird
        # later resolve number vs. expression
        type == :literal_value or type == :literal_expression ->
          name = Symbol.generate_name(type)

          {op_value ||| indirect_bit(indirect?), 0, name, address_definition}

        type == :no_address ->
          {op_value, 0, "", nil}

        # flag an error to developer
        true ->
          {op_value ||| 0o77777777, 0, "", nil}
      end

    memory_entry =
      Memory.memory(
        relocation,
        current_location,
        instruction_relocation,
        new_op_value,
        symbol_name,
        :mem_addr
      )

    new_aout =
      %{aout | memory: [memory_entry | aout.memory]}
      |> ADotOut.update_label_in_symbol_table()
      |> ADotOut.increment_current_location()
      |> ADotOut.handle_address_symbol(symbol_name, symbol)

    # if current_location == 1 do
    #   dbg(new_aout)
    # end

    new_aout
    # can add symbol, indirect, or indexed to hd(aout.memory).
  end

  def op_indirect(nil), do: false

  def op_indirect({:asterisk, _asterisk}), do: true

  def op_indirect({_, _}), do: false

  def indirect_bit(indirect?) when is_boolean(indirect?) do
    cond do
      indirect? -> @indirect
      true -> 0
    end
  end

  def opcode_map() do
    %{
      "STA" => {0o35_00000, :mem_addr},
      "STB" => {0o36_00000, :mem_addr},
      "STX" => {0o37_00000, :mem_addr},
      "XMA" => {0o62_00000, :mem_addr},
      "LDX" => {0o71_00000, :mem_addr},
      "LDB" => {0o75_00000, :mem_addr},
      "LDA" => {0o76_00000, :mem_addr},
      "EAX" => {0o77_00000, :mem_addr},
      "SUB" => {0o54_00000, :mem_addr},
      "ADD" => {0o55_00000, :mem_addr},
      "SUC" => {0o56_00000, :mem_addr},
      "ADC" => {0o57_00000, :mem_addr},
      "MIN" => {0o61_00000, :mem_addr},
      "ADM" => {0o63_00000, :mem_addr},
      "MUL" => {0o64_00000, :mem_addr},
      "DIV" => {0o65_00000, :mem_addr},
      "ETR" => {0o14_00000, :mem_addr},
      "MRG" => {0o16_00000, :mem_addr},
      "EOR" => {0o17_00000, :mem_addr},
      "RCH" => {0o46_00000, :rch_addr},
      "CLA" => {0o46_00001, :no_addr},
      "CLB" => {0o46_00002, :no_addr},
      "CLAB" => {0o46_00003, :no_addr},
      "CAB" => {0o46_00004, :no_addr},
      "CBA" => {0o46_00010, :no_addr},
      "XAB" => {0o46_00014, :no_addr},
      "CBX" => {0o46_00020, :no_addr},
      "CXB" => {0o46_00040, :no_addr},
      "XXB" => {0o46_00060, :no_addr},
      "STE" => {0o46_00122, :no_addr},
      "LDE" => {0o46_00140, :no_addr},
      "XEE" => {0o46_00160, :no_addr},
      "CXA" => {0o46_00200, :no_addr},
      "CAX" => {0o46_00400, :no_addr},
      "XXA" => {0o46_00600, :no_addr},
      "CNA" => {0o46_01000, :no_addr},
      "BAC" => {0o46_00012, :no_addr},
      "ABC" => {0o46_00005, :no_addr},
      "CLR" => {0o2_46_00003, :no_addr},
      "CLX" => {0o2_46_00000, :no_addr},
      "AXC" => {0o46_00401, :no_addr},
      "BRU" => {0o01_00000, :mem_addr},
      "BRX" => {0o41_00000, :mem_addr},
      "BRM" => {0o43_00000, :mem_addr},
      "BRR" => {0o51_00000, :mem_addr},
      "SKE" => {0o50_00000, :mem_addr},
      "SKB" => {0o52_00000, :mem_addr},
      "SKN" => {0o53_00000, :mem_addr},
      "SKR" => {0o60_00000, :mem_addr},
      "SKM" => {0o70_00000, :mem_addr},
      "SKA" => {0o72_00000, :mem_addr},
      "SKG" => {0o73_00000, :mem_addr},
      "SKD" => {0o74_00000, :mem_addr},
      "LRSH" => {0o66_24000, :shift_addr},
      "RSH" => {0o66_00000, :shift_addr},
      "RCY" => {0o66_20000, :shift_addr},
      "LSH" => {0o67_00000, :shift_addr},
      "LCY" => {0o67_20000, :shift_addr},
      "NOD" => {0o67_10000, :shift_addr},
      "NODCY" => {0o67_30000, :shift_addr},
      "HLT" => {0o00_00000, :no_addr},
      "NOP" => {0o20_00000, :mem_addr},
      "EXU" => {0o23_00000, :mem_addr},
      "ROV" => {0o02_20001, :no_addr},
      "REO" => {0o02_20010, :no_addr},
      "OVT" => {0o40_20001, :no_addr},
      "ZRO" => {0o00_00000, :mem_addr},

      # SYSPOPs defined by time sharing system

      "BIO" => {0o576_00000, :mem_addr},
      "BRS" => {0o573_00000, :mem_addr},
      "CIO" => {0o561_00000, :mem_addr},
      "CTRL" => {0o572_00000, :mem_addr},
      "DBI" => {0o542_00000, :mem_addr},
      "DBO" => {0o543_00000, :mem_addr},
      "DWI" => {0o544_00000, :mem_addr},
      "DWO" => {0o545_00000, :mem_addr},
      "EXS" => {0o552_00000, :mem_addr},
      "FAD" => {0o556_00000, :mem_addr},
      "FDV" => {0o553_00000, :mem_addr},
      "FMP" => {0o554_00000, :mem_addr},
      "FSB" => {0o555_00000, :mem_addr},
      "GCD" => {0o537_00000, :mem_addr},
      "GCI" => {0o565_00000, :mem_addr},
      "ISC" => {0o541_00000, :mem_addr},
      "IST" => {0o550_00000, :mem_addr},
      "LAS" => {0o546_00000, :mem_addr},
      "LDP" => {0o566_00000, :mem_addr},
      "LIO" => {0o552_00000, :mem_addr},
      "OST" => {0o551_00000, :mem_addr},
      "SAS" => {0o547_00000, :mem_addr},
      "SBRM" => {0o570_00000, :mem_addr},
      "SBRR" => {0o510_00000, :mem_addr},
      "SIC" => {0o540_00000, :mem_addr},
      "SKSE" => {0o563_00000, :mem_addr},
      "SKSG" => {0o562_00000, :mem_addr},
      "STI" => {0o536_00000, :mem_addr},
      "STP" => {0o567_00000, :mem_addr},
      "TCI" => {0o574_00000, :mem_addr},
      "TCO" => {0o575_00000, :mem_addr},
      "WCD" => {0o535_00000, :mem_addr},
      "WCH" => {0o564_00000, :mem_addr},
      "WCI" => {0o557_00000, :mem_addr},
      "WIO" => {0o560_00000, :mem_addr},

      # POPs
      "POP00" => {0o10000000, :mem_addr},
      "POP01" => {0o10100000, :mem_addr},
      "POP02" => {0o10200000, :mem_addr},
      "POP03" => {0o10300000, :mem_addr},
      "POP04" => {0o10400000, :mem_addr},
      "POP05" => {0o10500000, :mem_addr},
      "POP06" => {0o10600000, :mem_addr},
      "POP07" => {0o10700000, :mem_addr},
      "POP10" => {0o11000000, :mem_addr},
      "POP11" => {0o11100000, :mem_addr},
      "POP12" => {0o11200000, :mem_addr},
      "POP13" => {0o11300000, :mem_addr},
      "POP14" => {0o11400000, :mem_addr},
      "POP15" => {0o11500000, :mem_addr},
      "POP16" => {0o11600000, :mem_addr},
      "POP17" => {0o11700000, :mem_addr},
      "POP20" => {0o12000000, :mem_addr},
      "POP21" => {0o12100000, :mem_addr},
      "POP22" => {0o12200000, :mem_addr},
      "POP23" => {0o12300000, :mem_addr},
      "POP24" => {0o12400000, :mem_addr},
      "POP25" => {0o12500000, :mem_addr},
      "POP26" => {0o12600000, :mem_addr},
      "POP27" => {0o12700000, :mem_addr},
      "POP30" => {0o13000000, :mem_addr},
      "POP31" => {0o13100000, :mem_addr},
      "POP32" => {0o13200000, :mem_addr},
      "POP33" => {0o13300000, :mem_addr},
      "POP34" => {0o13400000, :mem_addr},
      "POP35" => {0o13500000, :mem_addr},
      "POP36" => {0o13600000, :mem_addr},
      "POP37" => {0o13700000, :mem_addr},
      "POP40" => {0o14000000, :mem_addr},
      "POP41" => {0o14100000, :mem_addr},
      "POP42" => {0o14200000, :mem_addr},
      "POP43" => {0o14300000, :mem_addr},
      "POP44" => {0o14400000, :mem_addr},
      "POP45" => {0o14500000, :mem_addr},
      "POP46" => {0o14600000, :mem_addr},
      "POP47" => {0o14700000, :mem_addr},
      "POP50" => {0o15000000, :mem_addr},
      "POP51" => {0o15100000, :mem_addr},
      "POP52" => {0o15200000, :mem_addr},
      "POP53" => {0o15300000, :mem_addr},
      "POP54" => {0o15400000, :mem_addr},
      "POP55" => {0o15500000, :mem_addr},
      "POP56" => {0o15600000, :mem_addr},
      "POP57" => {0o15700000, :mem_addr},
      "POP60" => {0o16000000, :mem_addr},
      "POP61" => {0o16100000, :mem_addr},
      "POP62" => {0o16200000, :mem_addr},
      "POP63" => {0o16300000, :mem_addr},
      "POP64" => {0o16400000, :mem_addr},
      "POP65" => {0o16500000, :mem_addr},
      "POP66" => {0o16600000, :mem_addr},
      "POP67" => {0o16700000, :mem_addr},
      "POP70" => {0o17000000, :mem_addr},
      "POP71" => {0o17100000, :mem_addr},
      "POP72" => {0o17200000, :mem_addr},
      "POP73" => {0o17300000, :mem_addr},
      "POP74" => {0o17400000, :mem_addr},
      "POP75" => {0o17500000, :mem_addr},
      "POP76" => {0o17600000, :mem_addr},
      "POP77" => {0o17700000, :mem_addr},

      # System POPs
      "SYSPOP00" => {0o50000000, :mem_addr},
      "SYSPOP01" => {0o50100000, :mem_addr},
      "SYSPOP02" => {0o50200000, :mem_addr},
      "SYSPOP03" => {0o50300000, :mem_addr},
      "SYSPOP04" => {0o50400000, :mem_addr},
      "SYSPOP05" => {0o50500000, :mem_addr},
      "SYSPOP06" => {0o50600000, :mem_addr},
      "SYSPOP07" => {0o50700000, :mem_addr},
      "SYSPOP10" => {0o51000000, :mem_addr},
      "SYSPOP11" => {0o51100000, :mem_addr},
      "SYSPOP12" => {0o51200000, :mem_addr},
      "SYSPOP13" => {0o51300000, :mem_addr},
      "SYSPOP14" => {0o51400000, :mem_addr},
      "SYSPOP15" => {0o51500000, :mem_addr},
      "SYSPOP16" => {0o51600000, :mem_addr},
      "SYSPOP17" => {0o51700000, :mem_addr},
      "SYSPOP20" => {0o52000000, :mem_addr},
      "SYSPOP21" => {0o52100000, :mem_addr},
      "SYSPOP22" => {0o52200000, :mem_addr},
      "SYSPOP23" => {0o52300000, :mem_addr},
      "SYSPOP24" => {0o52400000, :mem_addr},
      "SYSPOP25" => {0o52500000, :mem_addr},
      "SYSPOP26" => {0o52600000, :mem_addr},
      "SYSPOP27" => {0o52700000, :mem_addr},
      "SYSPOP30" => {0o53000000, :mem_addr},
      "SYSPOP31" => {0o53100000, :mem_addr},
      "SYSPOP32" => {0o53200000, :mem_addr},
      "SYSPOP33" => {0o53300000, :mem_addr},
      "SYSPOP34" => {0o53400000, :mem_addr},
      "SYSPOP35" => {0o53500000, :mem_addr},
      "SYSPOP36" => {0o53600000, :mem_addr},
      "SYSPOP37" => {0o53700000, :mem_addr},
      "SYSPOP40" => {0o54000000, :mem_addr},
      "SYSPOP41" => {0o54100000, :mem_addr},
      "SYSPOP42" => {0o54200000, :mem_addr},
      "SYSPOP43" => {0o54300000, :mem_addr},
      "SYSPOP44" => {0o54400000, :mem_addr},
      "SYSPOP45" => {0o54500000, :mem_addr},
      "SYSPOP46" => {0o54600000, :mem_addr},
      "SYSPOP47" => {0o54700000, :mem_addr},
      "SYSPOP50" => {0o55000000, :mem_addr},
      "SYSPOP51" => {0o55100000, :mem_addr},
      "SYSPOP52" => {0o55200000, :mem_addr},
      "SYSPOP53" => {0o55300000, :mem_addr},
      "SYSPOP54" => {0o55400000, :mem_addr},
      "SYSPOP55" => {0o55500000, :mem_addr},
      "SYSPOP56" => {0o55600000, :mem_addr},
      "SYSPOP57" => {0o55700000, :mem_addr},
      "SYSPOP60" => {0o56000000, :mem_addr},
      "SYSPOP61" => {0o56100000, :mem_addr},
      "SYSPOP62" => {0o56200000, :mem_addr},
      "SYSPOP63" => {0o56300000, :mem_addr},
      "SYSPOP64" => {0o56400000, :mem_addr},
      "SYSPOP65" => {0o56500000, :mem_addr},
      "SYSPOP66" => {0o56600000, :mem_addr},
      "SYSPOP67" => {0o56700000, :mem_addr},
      "SYSPOP70" => {0o57000000, :mem_addr},
      "SYSPOP71" => {0o57100000, :mem_addr},
      "SYSPOP72" => {0o57200000, :mem_addr},
      "SYSPOP73" => {0o57300000, :mem_addr},
      "SYSPOP74" => {0o57400000, :mem_addr},
      "SYSPOP75" => {0o57500000, :mem_addr},
      "SYSPOP76" => {0o57600000, :mem_addr},
      "SYSPOP77" => {0o57700000, :mem_addr}
    }
  end

  def clean_for_new_statement(%ADotOut{} = aout) do
    aout
  end
end
