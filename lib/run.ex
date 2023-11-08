defmodule Run do
  def main(args) do
    args |> parse_args |> process
  end

  def process([]) do
    IO.puts "No arguments given"
  end

  def process({parm_list, arg_list, []}) do
    # IO.inspect({"o0", o0})
    A940.Asm.run(arg_list, parm_list)    # IO.puts "Hello #{options}"
  end

  def process({_, _, errors}) do
    IO.puts "errors in argument list"
    IO.inspect(errors)
  end

  defp parse_args(args) do
    args |> dbg
    # {options, second, third} = OptionParser.parse(args)
    OptionParser.parse(args, strict: [start: :integer, org: :integer, out: :string]) |> dbg
    # {options, second, third}
  end

end
