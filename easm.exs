options = System.argv() |> OptionParser.parse(strict: [list: :boolean])
{_, file_list, _} = options

Enum.each(
  file_list,
  &(Easm.ProcessAssemblerFile.process(&1)
    |> Enum.each(fn token_list ->
      IO.inspect(token_list, label: "line #{token_list.linenumber}")
    end))
)
