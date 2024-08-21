defmodule Easm.LexicalLine do
  # alias Easm.LexicalLine
  alias Easm.ADotOut

  defstruct tokens: [],
            original: "",
            label_tokens: [],
            operation_tokens: [],
            address_tokens: [],
            is_op: false,
            is_pseudo: false

  def new(%{original: o, tokens: t}) do
    %Easm.LexicalLine{tokens: t, original: o}
  end

  def clean_for_new_statement(%ADotOut{} = aout) do
    aout
  end
end
