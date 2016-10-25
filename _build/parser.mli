type token =
  | NUM of (int)
  | ID of (string)
  | END
  | LBRACK
  | RBRACK
  | DEF
  | FST
  | SND
  | ADD1
  | SUB1
  | LPAREN
  | RPAREN
  | LET
  | IN
  | EQUAL
  | COMMA
  | PLUS
  | MINUS
  | TIMES
  | IF
  | COLON
  | ELSECOLON
  | TRUE
  | FALSE
  | ISBOOL
  | ISPAIR
  | ISNUM
  | LAMBDA
  | EQEQ
  | LESS
  | GREATER
  | PRINT
  | EOF

val program :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> Expr.expr
