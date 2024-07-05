# Expression Processing

## Problem

The assembler must evaluate expressions in the address field. The addresses may be simple, like ```a + 1```, or more complicated, like ```3 * S10BEG - 1```.
Expressions must also track the relocation factor of each expression. Relocation is how a label symbol is adjusted to reflect the actual address at which that label exists.For simplification, there are three allowable relocation factors:

* zero
* one
* three

An expression with zero relocation is absolute and independent of where the code is loaded. For instance, ```(S10LEN + 2) / 3```, when S10LEN has a relocation factor of zero, will have zero relocation factor.

Another example is ```LISTEND-LISTBEG+1```, where both LISTBEG and LISTEND have relocation factors of one has a relocation factor of zero.

Relocation factor of three will often apply to string pointers, which are character addresses made by multiplying the word address by three and adding zero, one, or two, for the left, middle, and right (MSB, mid, LSB) bytes. For example: ```S10BEG*3-1```.

## Data

The inputs are a list of {:type, "value"} tokens, a symbol table, and the current location.

## Plan

append to the input a ```{:operator, ")"}``` token; push ```{:operator, "("}``` token on the operator stack to initialize

```eval(tokens)``` calls

```eval(tokens ++ {:operator, ")"}, [{:operator, "("}], [], [expectations])```

the ```[expectations]``` can have :operator, :number, :symbol, :unary, :open_paren, :closed_paren, :asterisk.

```eval/4``` looks at the first (current) token, ensures it is in ```[expectations]```.

* if it is a number, a symbol, or * (just another symbol) then it is pushed on the values stack.
* if an operator, its priority is compared with the priority of the top of the operator stack.
* if P(in-hand) > P(on-stack) then push the operator and advance tokens
* otherwise eval the top of the operator stack with the one or two on top of the value stack and push the result back on the value stack.
* ```)``` matching ```(```: pop the ```(``` and advance tokens
* otherwise (not matching parens), loop to the step of comparing operator priorities.

### Expectations

Here are some expectations:

* a value can be followed by an operator
* an operator can be followed by a value
* a close parenthesis can be followed by an operator
* an open parenthesis can be followed by a unary operator or a value

Values are ```{number, relocation}```. The relocation is often 0, 1, or 3. The relocation component is subject to the same arithmetic operations as the values.

It is theoretically possible that there will be an expression like

```
9 * R1 - R2 - R3 - R4 - R5 - R6 - R7 - R8 - R9
```

which according to the rules above will have a relocation value of one. God help any developers who do that.

### Error detection

When there are no more tokens, the operator stack should be empty and the value stack should have one value on it, which should have a relocation of 0, 1, or 3. Not sure what to do if the relocation is something else.

When processing tokens, the token in hand should be of a category that is in the ```[expectations]``` list.

## Testing

Tests should be written for this stuff:

1. priority({:operator, op} = operator_token)
1. is_lower_priority?(operator_token0, operator_token1)
1. handle_one_token when the token will cause
a. operator push
b. value push
c. evaluation
1. evaluate correctly formatted expression
a. number
b. symbol
c. symbol plus/minus number
d. numerical expression with multiple operators of the same priority
e. numerical expressions with parenthetical sub-expressions.
f. expressions evaluating to relocation factors of zero, one, and three
g expressions evaluating to unacceptable relocation factors.
h. expressions which cannot be evaluated due to un-"known" symbols (e.g. external)
i. expressions that have an error: ```A+*B```.

### Helper Function(s)

```symbol_table``` creates a symbol table with
a. A0, A1, and A2 with zero (absolute) relocation factors, b. R0, R1, and R2 with relocation factors of one,
c. U0, U1, and U2 defined but not known

```get_tokens``` from a string, where variables are as above. ```( ) + - * /``` for operators. Spaces are ignored.

```new_symbol``` creates a symbol
