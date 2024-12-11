open Core

let read lexbuf =
  let context = Parser.context Lexer.read lexbuf in
  print_s [%message (context : Ast.context)]
;;

let parse filename () =
  let inx = In_channel.create filename in
  let lexbuf = Lexing.from_channel inx in
  lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = filename };
  read lexbuf;
  In_channel.close inx
;;

let () =
  Command.basic_spec
    ~summary:"test lexer + parser"
    Command.Spec.(empty +> anon ("filename" %: string))
    parse
  |> Command_unix.run
;;
