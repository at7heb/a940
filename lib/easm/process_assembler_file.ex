defmodule Easm.ProcessAssemblerFile do
  alias Easm.ADotOut
  alias Easm.LexicalLine
  alias Easm.Assembly
  alias Easm.Lexer

  def do_one_file(file_path)
      when is_binary(file_path) do
    read_and_condition_source(file_path)
    |> run_lexer()
    |> find_parts()
    |> assemble_file()
    |> resolve_symbols()
    |> output(file_path)
  end

  def read_and_condition_source(filepath) do
    File.read!(filepath)
    |> String.upcase()
    |> String.replace("\t", " ")
    |> String.replace("\r", "")
    |> String.split("\n")
    |> Enum.map(&String.trim_trailing(&1, "\n"))
  end

  def run_lexer(source_lines) when is_list(source_lines) do
    source_lines
    |> Lexer.analyze()
    |> Enum.map(fn line_map -> {line_map.linenumber, LexicalLine.new(line_map)} end)
    |> Enum.reduce(%{}, fn {line_number, lexical_line}, lexical_line_map ->
      Map.put_new(lexical_line_map, line_number, lexical_line)
    end)
    |> make_aout()
  end

  def find_parts(%ADotOut{lines: lines} = aout) do
    new_lines = Enum.map(lines, fn lex_line -> Lexer.find_parts(lex_line) end)
    %{aout | lines: new_lines}
  end

  def assemble_file(%ADotOut{} = aout) do
    current_line = Map.get(aout.lines, :current_line) + 1

    cond do
      current_line > aout.line_count -> aout
      true -> assemble_line(aout, current_line) |> assemble_file()
    end
  end

  def assemble_line(%ADotOut{} = aout, line_number) when is_integer(line_number) do
    Assembly.initialize_for_a_line_assembly(aout, line_number)
    |> Assembly.assemble_lexons(line_number)
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
