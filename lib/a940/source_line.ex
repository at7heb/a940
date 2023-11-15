defmodule A940.SourceLine do
  require Record

  Record.defrecord(:sourceline,
    text: "",
    linenumber: 0,
    label: "",
    opcode: "",
    address: "",
    indirect: false,
    indexed: false,
    type: :yslabelysaddress,
    location: -1,
    inhalt: {:type, [0]}
  )

  @type sourceline ::
          record(
            :sourceline,
            text: String.t(),
            linenumber: Integer.t(),
            label: String.t(),
            opcode: String.t(),
            address: String.t(),
            indirect: Atom.t(),
            indexed: Atom.t(),
            type: Atom.t(),
            location: Integer.t(),
            inhalt: Tuple.t()
          )
end
