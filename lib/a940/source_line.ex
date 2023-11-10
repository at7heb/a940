defmodule A940.SourceLine do
  require Record
  Record.defrecord(:sourceline, text: "a lda 5000", label: "a", opcode: "lda", address: "5000", type: :ys_label_ys_address)

  @type sourceline :: record(
      :sourceline, text: String.t(), label: String.t(), opcode: String.t(), address:  String.t(), type: Atom.t()
    )
end
