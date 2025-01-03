{
open Lexing
open Parser

exception SyntaxError of string
}

let prob = "0" | "1" | "1.0" | "0." ['0'-'9']*
let ident = ['a'-'z' 'A'-'Z' '_'] ['a'-'z' 'A'-'Z' '0'-'9' '_']*
let white = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"

rule read =
  parse
  | white    { read lexbuf }
  | newline  { new_line lexbuf; read lexbuf }
  | prob     { PROB (float_of_string (Lexing.lexeme lexbuf)) }
  | ":"      { COLON }
  | "."      { DOT }
  | ","      { COMMA }
  | "end"    { END }
  | "mu"     { MU }    (* TODO: maybe use unicode for these *)
  | "(+)"    { OPLUS }
  | "&"      { AND }
  | "{"      { LBRACE }
  | "}"      { RBRACE }
  | "("      { LPAREN }
  | ")"      { RPAREN }
  | "Int"    { INT }
  | "Str"    { STR }
  | "Bool"   { BOOL }
  | ident    { IDENT (Lexing.lexeme lexbuf) }
  | _        { raise (SyntaxError ("Unexpected char: " ^ Lexing.lexeme lexbuf)) }
  | eof      { EOF }
