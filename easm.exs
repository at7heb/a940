# alias Easm.ADotOut

defmodule E do
  def print_listing(listing_list) do
    Enum.each(listing_list, &IO.puts(&1))
  end
end

options = System.argv() |> OptionParser.parse(strict: [list: :boolean])
{_, file_list, _} = options

Enum.each(
  file_list,
  fn path ->
    aout = Easm.ProcessAssemblerFile.do_one_file(path)
    E.print_listing(Enum.reverse(aout.listing))
  end
)
