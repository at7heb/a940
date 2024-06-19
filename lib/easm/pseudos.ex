defmodule Easm.Pseudos do
  alias Easm.ADotOut

  def pseudo_op_lookup(op) when is_binary(op) do
    op_type = Map.get(pseudo_op_map(), op)

    cond do
      op_type == nil -> :not_pseudo
      true -> {:ok, op_type}
    end
  end

  def handle_pseudo(%ADotOut{} = aout, {:ok, op_type}) do
    aout
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
