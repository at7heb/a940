# alias Easm.ADotOut

defmodule E do
  def print_listing(listing_list) do
    Enum.each(listing_list, &IO.puts(Easm.ListingLine.to_string(&1)))
  end

  def print_memory(memory) do
    Enum.reverse(memory)
    |> Enum.each(fn mem ->
      IO.puts(
        Integer.to_string(mem.location, 8) <>
          " " <>
          Integer.to_string(mem.address_relocation) <> " " <> Integer.to_string(mem.content, 8)
      )
    end)
  end
end

options = System.argv() |> OptionParser.parse(strict: [list: :boolean])
{_, file_list, _} = options

Enum.each(
  file_list,
  fn path ->
    aout = Easm.ProcessAssemblerFile.do_one_file(path)
    # E.print_memory(aout.memory)
    E.print_listing(Enum.reverse(aout.listing))
  end
)
