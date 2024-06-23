defmodule Easm.LexicalLine do
  alias Easm.LexicalLine
  defstruct tokens: [], original: "", label_tokens: [], operation_tokens: [], address_tokens: []

  def new(%{original: o, tokens: t}) do
    %Easm.LexicalLine{tokens: t, original: o}
  end
end
