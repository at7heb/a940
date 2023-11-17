defmodule Run do
  # to decode a binary place file: ./a940 --decode=junk
  # to assemble, ./a940 --start=1024 --org=1024 --out=junk test.a940
  def main(args) do
    args |> parse_args |> process
  end

  def process({[], [], []}) do
    IO.puts("No arguments given")
    IO.puts("use ./a940 --start=<address> --org=<address> out=<outfile> <sourcefile>")
  end

  def process({parm_list, arg_list, []}) do
    # IO.inspect({"o0", o0})
    # IO.puts "Hello #{options}"
    {parm_list, arg_list} |> dbg

    if length(parm_list) == 1 do
      disasm(parm_list)
    else
      A940.Asm.run(arg_list, parm_list)
    end
  end

  def process({_, _, errors}) do
    IO.puts("errors in argument list")
    IO.inspect(errors)
  end

  defp parse_args(args) do
    # {options, second, third} = OptionParser.parse(args)
    OptionParser.parse(args,
      strict: [start: :integer, org: :integer, out: :string, decode: :string]
    )

    # {options, second, third}
  end

  def disasm([decode: filename] = _parmlist) do
    {:ok, file} = File.open(filename, [:read, :binary])
    data = IO.binread(file, :eof)
    dis_list(data)
  end

  def dis_list(<<>>), do: nil

  def dis_list(<<word::24, rest::binary>>) do
    # word = c + 256 * (b + 256 * a)
    Integer.to_string(word, 8) |> String.pad_leading(8, "0") |> IO.puts()
    dis_list(rest)
  end
end
