defmodule Easm.LexicalLine do
  defstruct tokens: [], original: ""

  def new(%{original: o, tokens: t}) do
    %Easm.LexicalLine{tokens: t, original: o}
  end
end
