defmodule Easm.LexicalLine do
  defstruct tokens: [], original: "", linenumber: 0

  def new(%{original: o, tokens: t, linenumber: ln}) do
    %Easm.LexicalLine{tokens: t, original: o, linenumber: ln}
  end
end
