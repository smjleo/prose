open Core
module Parser = Prose.Parser
module Lexer = Prose.Lexer
module Ast = Prose.Ast
module Action = Prose.Action
module Translate = Prose.Translate
module Prism = Prose.Prism
module Printer = Prose.Printer
module Psl = Prose.Psl

let parse lexbuf =
  try Parser.context Lexer.read lexbuf with
  | Parser.Error ->
    let pos = lexbuf.lex_curr_p in
    let line = pos.pos_lnum in
    let column = pos.pos_cnum - pos.pos_bol in
    error_s [%message "Syntax error" (line : int) (column : int)] |> ok_exn
;;

let output ctx_file ?model_output_file ?prop_output_file ~print_ast () =
  let dbg_print_s sexp = if print_ast then print_s sexp in
  let inx = In_channel.create ctx_file in
  let lexbuf = Lexing.from_channel inx in
  lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = ctx_file };
  let context = parse lexbuf in
  dbg_print_s [%message (context : Ast.context)];
  let translated, properties = Translate.translate context in
  dbg_print_s [%message (translated : Prism.model)];
  Printer.print_model ?output_file:model_output_file translated;
  Printer.print_properties ?output_file:prop_output_file properties;
  In_channel.close inx
;;

type checked_output =
  { safety : string
  ; pdf : string
  ; normalised_pdf : string
  ; termination : string
  }

let parse_prism_output lines =
  let results =
    List.fold_left lines ~init:[] ~f:(fun accum line ->
      match String.is_prefix line ~prefix:"Result: " with
      | false -> accum
      | true -> line :: accum)
    |> List.rev
  in
  match results with
  | [ safety; pdf; normalised_pdf; termination ] ->
    { safety; pdf; normalised_pdf; termination }
  | _ ->
    let full_output = String.concat ~sep:"\n" lines in
    error_s
      [%message
        "PRISM output contains an unexpected number of results, likely PRISM returned an \
         error"
          full_output
          (results : string list)]
    |> ok_exn
;;

let print_output { pdf; normalised_pdf; safety; termination } =
  print_endline "Type safety";
  print_endline safety;
  print_endline "\nProbabilistic deadlock freedom";
  print_endline pdf;
  print_endline "\nNormalised probabilistic deadlock freedom";
  print_endline normalised_pdf;
  print_endline "\nProbabilistic termination";
  print_endline termination
;;

let verify ctx_file ~print_ast () =
  let model_output_file = Filename_unix.temp_file "model" ".prism" in
  let prop_output_file = Filename_unix.temp_file "properties" ".props" in
  output ctx_file ~model_output_file ~prop_output_file ~print_ast ();
  let prism =
    Core_unix.create_process ~prog:"prism" ~args:[ model_output_file; prop_output_file ]
  in
  let stdout = Core_unix.in_channel_of_descr prism.stdout in
  let stderr = Core_unix.in_channel_of_descr prism.stderr in
  let lines = In_channel.input_lines stdout in
  let stderr_output = In_channel.input_all stderr in
  if String.length stderr_output <> 0
  then error_s [%message "PRISM returned error when verifying" stderr_output] |> ok_exn;
  let output = parse_prism_output lines in
  print_output output;
  Core_unix.remove model_output_file;
  Core_unix.remove prop_output_file
;;

let ctx_file_flag =
  let open Command.Param in
  anon ("ctx_file" %: string)
;;

let print_ast_flag =
  let open Command.Param in
  flag
    "-print-ast"
    no_arg
    ~doc:" Print internal AST representation for debugging purposes"
;;

let output_command =
  Command.basic
    ~summary:
      "Compile given session type context into a PRISM model and properties, and output \
       them."
    (let%map_open.Command ctx_file = ctx_file_flag
     and model_output_file =
       flag
         "-o"
         (optional string)
         ~doc:"string Write PRISM model output to filename (default: print to stdout)"
     and prop_output_file =
       flag
         "-p"
         (optional string)
         ~doc:"string Write PRISM property output to filename (default: print to stdout)"
     and print_ast = print_ast_flag in
     output ctx_file ?model_output_file ?prop_output_file ~print_ast)
;;

let verify_command =
  Command.basic
    ~summary:
      "Verify probabilistic properties of the given session type context using PRISM."
    (let%map_open.Command ctx_file = ctx_file_flag
     and print_ast = print_ast_flag in
     verify ctx_file ~print_ast)
;;

let command =
  Command.group
    ~summary:
      "Commands to either verify the probilistic session type or output PRISM files for \
       inspection."
    [ "output", output_command; "verify", verify_command ]
;;

let () = Command_unix.run command
