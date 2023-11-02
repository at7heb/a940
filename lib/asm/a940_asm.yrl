Nonterminals
  prog
  pseudo
  statement
  statements
.

Terminals
 int
 intx
 into
 label
 opcode
 '*'
 ','
 '='
 ' '
 ';'
.

Rootsymbol
  prog
.

Right 100 '='.
Left 300 '*'.
Left 300 ','.
Left 400 ' '.
Left 100 ';'.

prog -> statements : $1.

statements -> statement : '$1'.
statements -> statement statements : lists:merge('$1', '$2').

statement -> ' ' opcode ' ' number ';'.
statement -> ' ' opcode '*' ' ' number ';'.
statement -> ' ' opcode ' ' number ',' number ';'.
statement -> label ' ' opcode.
statement -> label ' ' opcode '*' ' ' number ';'.
statement -> label ' ' opcode ' ' number ',' number ';'.

number -> int : unwrap('$1').
number -> into : unwrapo('$1').
number -> intx : unwrapx('$1').

Erlang code.

unwrap({int, Line, Value}) -> {int, Line, list_to_integer(Value)}.
unwrapo({int, Line, Value}) -> {int, Line, list_to_integer(Value, 8)}.
unwrapx({int, Line, Value}) -> {int, Line, list_to_integer(Value, 16)}.
