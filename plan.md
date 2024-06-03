# Assembler Plan

Keep it simple.

## Formats

``` code
* comment line
<label> <statement>
or
<statement>

<label>: [a-zA-Z][a-zA-Z0-9_]*
statement: <ws> <opcode & addr> <ws> <mem-addr>
statement: <ws> <opcode & sub-op> <ws> <address number>
statement: <ws> <opcode & shift> <ws> <shift count>
statement: <ws> <opcode & shift indirect> <ws> <indirect mem-addr>
statement: <ws> <data-defining> <ws> <number>
statement: <ws> <string-defining> <ws> <string>
statement: <ws> <origin definition> <ws> <number>
statement: <ws> <start definition> <ws> <number>
statement: <ws> <end>

<mem-addr>: <unadorned symbol>
<mem-addr>: <number>
<mem-addr>: <r3 expression>
#<mem-addr>: <r1 expression> !!!NOT YET!!!
<mem-addr>: <r0 expression>
<r0 expression>: <number> or <symbol defined after ORG>
<r1 expression>: <not yet>
<r3 expression>: &<r0 expression>
<number>: [0-9_]+ or [0-7_]+B or [01]+M

<data-defining>: DATA 
<string-defining>: STRING
<string>: quoted string with \nnn escapes
<origin definition>: ORG ### DEFERRED
<start definition>: START ### DEFERRED
<end>: END ###DEFERRED
```
BNf Expressions
```
<exp> ::= <exp> + <term> | <exp> - <term> | <term>
<term> ::= <term> * <power> | <term> / <power> | <power>
<power> ::= <factor> ^ <power> | <factor>
<factor> ::= ( <exp> ) | <int>
<int> ::= <digit> <int> | <digit>
<digit> ::= 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
```

Except modify factor:
```
<factor> ::= -<factor> | ( <exp> ) | <value>
<value> ::= <symbol> | <int> | <chars_6_bit> | <chars_8_bit>
