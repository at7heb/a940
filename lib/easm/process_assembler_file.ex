defmodule Easm.ProcessAssemblerFile do
  def process(filepath) do
    inhalt =
      File.read!(filepath)
      |> String.upcase()
      |> String.split("\n")
      |> Enum.map(&(String.trim_trailing(&1, "\n") |> String.trim_trailing("\r")))
      |> Enum.take(15)

    _tokens = Easm.Lexer.analyze(inhalt) |> IO.inspect()
  end
end
