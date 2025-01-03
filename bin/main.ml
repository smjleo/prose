open Core
module Parser = Prose.Parser
module Lexer = Prose.Lexer
module Ast = Prose.Ast
module Action = Prose.Action
module Translate = Prose.Translate
module Prism = Prose.Prism
module Printer = Prose.Printer

let parse lexbuf = Parser.context Lexer.read lexbuf

let main filename () =
  let inx = In_channel.create filename in
  let lexbuf = Lexing.from_channel inx in
  lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = filename };
  let context = parse lexbuf in
  print_s [%message (context : Ast.context)];
  let translated = Translate.translate context in
  print_s [%message (translated : Prism.model)];
  Printer.print translated;
  In_channel.close inx
;;

let () =
  Command.basic_spec
    ~summary:"test"
    Command.Spec.(empty +> anon ("filename" %: string))
    main
  |> Command_unix.run
;;
