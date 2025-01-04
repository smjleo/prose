open Core
module Parser = Prose.Parser
module Lexer = Prose.Lexer
module Ast = Prose.Ast
module Action = Prose.Action
module Translate = Prose.Translate
module Prism = Prose.Prism
module Printer = Prose.Printer

let parse lexbuf = Parser.context Lexer.read lexbuf

let main ctx_file ?output_file ~print_ast () =
  let dbg_print_s sexp = if print_ast then print_s sexp in
  let inx = In_channel.create ctx_file in
  let lexbuf = Lexing.from_channel inx in
  lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = ctx_file };
  let context = parse lexbuf in
  dbg_print_s [%message (context : Ast.context)];
  let translated = Translate.translate context in
  dbg_print_s [%message (translated : Prism.model)];
  Printer.print ?output_file translated;
  In_channel.close inx
;;

let command =
  (* TODO: These set of args is meant for this version of Prose, which only
     translates into PRISM without running property verification. Once this
     is implemented, these should be adjusted accordingly (for example, only
     save PRISM file with a flag, etc.) *)
  Command.basic
    ~summary:"Compile given session type context into PRISM"
    (let%map_open.Command ctx_file = anon ("ctx_file" %: string)
     and output_file =
       flag "-o" (optional string) ~doc:"string Write PRISM output to filename"
     and print_ast =
       flag
         "-print-ast"
         no_arg
         ~doc:" Print internal AST representation for debugging purposes"
     in
     main ctx_file ?output_file ~print_ast)
;;

let () = Command_unix.run command
