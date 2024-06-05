options = System.argv() |> OptionParser.parse(strict: [list: :boolean])
{_, file_list, _} = options

Enum.each(file_list, &Easm.ProcessAssemblerFile.process(&1))
