defmodule A940.SourceLine do
  require Record

  Record.defrecord(:sourceline,
    text: "",
    linenumber: 0,
    label: "",
    opcode: "",
    address: "",
    type: :yslabelysaddress,
    location: -1,
    inhalt: []
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
