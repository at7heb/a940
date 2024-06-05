defmodule Easm.Lexer do
  def analyze(lines) when is_list(lines) do
    Enum.map(lines, &analyze(&1))
    |> Enum.reduce({[], 1}, fn linemap, {lines, linecount} ->
      l = Map.put(linemap, :linenumber, linecount)
      {[l | lines], linecount + 1}
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  def analyze(line) when is_binary(line) do
    %{original: line, tokens: tokens(line)}
  end

  def tokens(line) when is_binary(line) do
    tokens(line, [])
  end

  def tokens("", token_list), do: Enum.reverse(token_list)

  def tokens(line, token_list) do
  end
end
