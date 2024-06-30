defmodule Easm.Pseudos do
  alias Easm.ADotOut
  alias Easm.LexicalLine
  alias Easm.Memory
  alias Easm.Symbol

  def pseudo_op_lookup(op) when is_binary(op) do
    op_type = Map.get(pseudo_op_map(), op)

    cond do
      op_type == nil -> :not_pseudo
      true -> {:ok, op_type}
    end
  end

  def handle_pseudo(%ADotOut{} = aout, %LexicalLine{} = _ll, {:ok, pseudo_type}) do
    memory_entry =
      Memory.memory(false, 16384, 0o77_777_777, %Symbol{}, :shift, {:pseudo_op, pseudo_type})

    %{aout | memory: [memory_entry | aout.memory]}
    # handle incrementing location for BSS, BES, DATA, ASC, etc when we get to the operand.
  end

  def pseudo_op_map() do
    %{
      "IDENT" => {:ident, :no_addr},
      "END" => {:end, :no_addr},
      "EQU" => {:equ, :expression},
      "DATA" => {:data, :number_list},
      "BSS" => {:bss, :expression},
      "ASC" => {:asc, :quoted_string},
      "OPD" => {:opd, :number_list},
      "BES" => {:bes, :expression},
      "IF" => {:if, :expression},
      "ELSE" => {:else, :no_addr},
      "ENDIF" => {:endif, :no_addr},
      "LIST" => {:list, :no_addr},
      "NOLIST" => {:nolist, :no_addr}
    }
  end
end
