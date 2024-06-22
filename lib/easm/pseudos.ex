defmodule Easm.Pseudos do
  alias Easm.ADotOut
  alias Easm.Symbol
  alias Easm.Memory

  def pseudo_op_lookup(op) when is_binary(op) do
    op_type = Map.get(pseudo_op_map(), op)

    cond do
      op_type == nil -> :not_pseudo
      true -> {:ok, op_type}
    end
  end

  def handle_pseudo(%ADotOut{} = aout, {:ok, pseudo_type}) do
    memory_entry =
      Memory.memory(false, 16384, 0o77_777_777, %Symbol{}, :shift, {:pseudo_op, pseudo_type})

    %{aout | memory: [memory_entry | aout.memory]}
    # handle incrementing location for BSS, BES, DATA, ASC, etc when we get to the operand.
  end

  def pseudo_op_map() do
    %{
      "IDENT" => :ident,
      "END" => :end,
      "EQU" => :equ,
      "DATA" => :data,
      "BSS" => :bss,
      "ASC" => :asc,
      "OPD" => :opd,
      "BES" => :bes,
      "IF" => :if,
      "ELSE" => :else,
      "ENDIF" => :endif,
      "LIST" => :list,
      "NOLIST" => :nolist
    }
  end
end
