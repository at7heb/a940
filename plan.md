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

BNF Expressions

``` bnf
<exp> ::= <exp> + <term> | <exp> - <term> | <term>
<term> ::= <term> * <power> | <term> / <power> | <power>
<power> ::= <factor> ^ <power> | <factor>
<factor> ::= ( <exp> ) | <int>
<int> ::= <digit> <int> | <digit>
<digit> ::= 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
```

These were copied from <https://athena.ecs.csus.edu/~gordonvs/135/resources/04bnfParseTrees.pdf>

These were copied from <https://athena.ecs.csus.edu/~gordonvs/135/resources/04bnfParseTrees.pdf>

Except modify factor:

```
<factor> ::= -<factor> | +<factor> | ( <exp> ) | <value>
<value> ::= <symbol> | <int> | <chars_6_bit> | <chars_8_bit> | <literal>
```

## Lexical Analysis

1. recognize decimal, octal, hex, and binary integers. No signs.
2. recognize symbols. Is case important? Should that be a flag?
3. recognize operators
4. recognize 6 bit character literals: 'a', 'ab', 'abc', or 'abcd'. Spaces are allowed.
5. recognize 8 bit character literals: "a", "ab", "abc". Spaces are allowed.
6. problem: * can be current location or can be multiply operator.

## Character Translation

The 940 software uses a character set where the code for the space is 0. All input output must ```SUB =40B; ETR =177B``` on input. On output, ```ADD =40B; ETR=177B```.

On the other hand, The assemly source is in normal ASCII, and so the assembler will use ascii.

Additionally, the ```ASC``` directive will translate the characters as for input/output, as above. The same is true for ```='abcd'```, excep that must use ```ETR =77B```

## Code translation

There should be an ```IDENT```; make it a must to simplify for now.
The IDENT label is used as the relocation reference in the a.out.
