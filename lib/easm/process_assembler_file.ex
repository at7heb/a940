defmodule Easm.ProcessAssemblerFile do
  alias Easm.ADotOut
  alias Easm.LexicalLine
  alias Easm.Assembly

  def do_one_file(file_path)
      when is_binary(file_path) do
    run_lexer(file_path)
    |> assemble()
    |> resolve_symbols()
    |> output(file_path)
  end

  def run_lexer(filepath) do
    File.read!(filepath)
    |> String.upcase()
    |> String.replace("\t", " ")
    |> String.replace("\r", "")
    |> String.split("\n")
    |> Enum.map(&String.trim_trailing(&1, "\n"))
    |> Easm.Lexer.analyze()
    |> Enum.map(fn line_map -> {line_map.linenumber, LexicalLine.new(line_map)} end)
    |> Enum.reduce(%{}, fn {line_number, lexical_line}, lexical_line_map ->
      Map.put_new(lexical_line_map, line_number, lexical_line)
    end)
    |> make_aout()

    # |> dbg
  end

  def assemble(%ADotOut{} = aout) do
    current_line = Map.get(aout.lines, :current_line) + 1

    cond do
      current_line > aout.line_count -> aout
      true -> Assembly.assemble_line(aout, current_line) |> assemble()
    end
  end

  def resolve_symbols(%ADotOut{} = aout) do
    aout
  end

  def output(%ADotOut{} = aout, file_path) when is_binary(file_path) do
    # use Path module to change file name to **.o
    # write output file
    IO.inspect(aout, label: "aout")
    IO.inspect(file_path, label: "File processed")
    aout
  end

  def make_aout(lines) when is_map(lines) do
    line_count = Map.keys(lines) |> Enum.max()

    new_lines =
      Map.put(lines, :current_line, 0)
      |> Map.put(:line_cursor, 0)
      |> Map.put(:location, 0)
      |> Map.put(:relocatable, true)
      |> Map.put(:content, 0)

    aout = %ADotOut{}

    %{aout | lines: new_lines, line_count: line_count, file_ok: true}
  end
end
