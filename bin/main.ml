open Core
module Parser = Prose.Parser
module Lexer = Prose.Lexer
module Ast = Prose.Ast
module Label = Prose.Label

let parse lexbuf = Parser.context Lexer.read lexbuf

let main filename () =
  let inx = In_channel.create filename in
  let lexbuf = Lexing.from_channel inx in
  lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = filename };
  let context = parse lexbuf in
  print_s [%message (context : Ast.context)];
  let labels = Label.in_context context in
  print_s [%message (labels : Label.LSet.t)];
  In_channel.close inx
;;

let () =
  Command.basic_spec
    ~summary:"test"
    Command.Spec.(empty +> anon ("filename" %: string))
    main
  |> Command_unix.run
;;
