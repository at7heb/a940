Definitions
INTD = [0-9]+
INTX = [0-9a-fA-F]+
INTO = [0-7]+
LABL = [a-zA-Z][a-zA-Z0-9]*
OPCD = [A-Z]+
WHIT = [s\t\n\r]+

Rules.
\,	: {token, {',', TokenLine}}.
\*	: {token, {'*', TokenLine}}.
\=	: {token, {'=', TokenLine}}.
\;	: {token, {';', TokenLine}}.
{INTD}	: {token, {int, TokenLine, TokenChars}}.
{INTO}	: {token, {into, TokenLine, TokenChars}}.
{INTX}	: {token, {intx, TokenLine, TokenChars}}.
{LABL}  : {token, {label, TokenLine, TokenChars}}.
{OPCD}	: {token, {opcode, TokenLine, TokenChars}}.
{WHIT}	: {token, {' ', TokenLine}}.

Erlang code.
to_atom([$:|Chars]) ->
  list_to_atom(Chars).
