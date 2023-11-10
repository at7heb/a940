defmodule A940.SourceLine do
  require Record

  Record.defrecord(:sourceline,
    text: "a lda 5000B",
    linenumber: 1,
    label: "a",
    opcode: "lda",
    address: "5000",
    type: :ys_label_ys_address,
    location: 1024,
    inhalt: [0o07605000]
  )

  @type sourceline ::
          record(
            :sourceline,
            text: String.t(),
            linenumber: Integer.t(),
            label: String.t(),
            opcode: String.t(),
            address: String.t(),
            type: Atom.t(),
            location: Integer.t(),
            inhalt: []
          )
end
