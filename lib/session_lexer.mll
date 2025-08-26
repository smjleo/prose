{
open Lexing
open Session_parser

exception SyntaxError of string
}

let prob = "1.0" | "0." ['0'-'9']*
let int = '-'? ['0'-'9']+
let ident = ['a'-'z' 'A'-'Z' '_'] ['a'-'z' 'A'-'Z' '0'-'9' '_']*
let white = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"

rule read =
  parse
  | white    { read lexbuf }
  | newline  { new_line lexbuf; read lexbuf }
  | int      { INT (int_of_string (Lexing.lexeme lexbuf)) }
  | prob     { PROB (float_of_string (Lexing.lexeme lexbuf)) }
  | "<-"     { ARROW }
  | "!"      { SEND }
  | "?"      { RECV }
  | "+"      { PLUS }
  | "."      { DOT }
  | "("      { LPAREN }
  | ")"      { RPAREN }
  | "{"      { LBRACE }
  | "}"      { RBRACE }
  | "=>"     { IMPLIES }
  | "|"      { PIPE }
  | "if"     { IF }
  | "then"   { THEN }
  | "else"   { ELSE }
  | "mu"     { MU }
  | "flip"   { FLIP }
  | "H"      { HEAD }
  | "T"      { TAIL }
  | "true"   { TRUE }
  | "false"  { FALSE }
  | "or"     { OR }
  | "-"      { NEG }
  | "succ"   { SUCC }
  | "<"      { LT }
  | "(+)"    { NONDET }
  | "nil"    { NIL }
  | "(*"     { comment lexbuf }
  | ident    { IDENT (Lexing.lexeme lexbuf) }
  | _        { raise (SyntaxError ("Unexpected char: " ^ Lexing.lexeme lexbuf)) }
  | eof      { EOF }

and comment =
  parse
  | "*)"     { read lexbuf }
  | newline  { new_line lexbuf; comment lexbuf }
  | eof      { raise (SyntaxError "Unexpected EOF with unterminated comment")}
  | _        { comment lexbuf }