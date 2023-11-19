defmodule Run do
  import Bitwise

  @address_mask 0o37777

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
    # {parm_list, arg_list} |> dbg

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
    dis_list(data, %{type: :start_address, address: 0})
  end

  def dis_list(<<>>, _), do: nil

  def dis_list(<<word::24, rest::binary>>, mem) do
    # word = c + 256 * (b + 256 * a)
    mem = handle_word(word, mem)
    dis_list(rest, mem)
  end

  def handle_word(word, %{type: :start_address} = mem) do
    word = word &&& @address_mask
    ["First: ", Integer.to_string(word, 8) |> String.pad_leading(8, " ")] |> IO.puts()
    %{mem | type: :end_address, address: word}
  end

  def handle_word(word, %{type: :end_address} = mem) do
    word = word &&& @address_mask
    ["Last:  ", Integer.to_string(word, 8) |> String.pad_leading(8, " ")] |> IO.puts()
    %{mem | type: :launch_address}
  end

  def handle_word(word, %{type: :launch_address} = mem) do
    word = word &&& @address_mask
    ["Launch:", Integer.to_string(word, 8) |> String.pad_leading(8, " "), "\n"] |> IO.puts()
    %{mem | type: :memory}
  end

  def handle_word(word, %{type: :memory, address: address} = mem) do
    [
      Integer.to_string(address, 8) |> String.pad_leading(5, " "),
      ": ",
      Integer.to_string(word, 8) |> String.pad_leading(8, "0")
    ]
    |> IO.puts()

    %{mem | address: address + 1 &&& @address_mask}
  end
end
