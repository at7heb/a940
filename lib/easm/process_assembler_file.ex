defmodule Easm.ProcessAssemblerFile do
  alias Easm.ADotOut
  alias Easm.LexicalLine

  def process(filepath) do
    lines =
      File.read!(filepath)
      |> String.upcase()
      |> String.replace("\t", " ")
      |> String.replace("\r", "")
      |> String.split("\n")
      |> dbg
      |> Enum.map(&String.trim_trailing(&1, "\n"))
      |> Easm.Lexer.analyze()
      |> Enum.map(fn line_map -> LexicalLine.new(line_map) end)
      |> dbg

    _new_aout =
      lines
      |> Enum.reduce(%ADotOut{}, fn line, a_out ->
        Easm.Parser.build_symbol_table(line, a_out)
      end)
  end
end
