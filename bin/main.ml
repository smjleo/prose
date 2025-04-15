open Core

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

let print_raw_prism_flag =
  let open Command.Param in
  flag "-raw-prism" no_arg ~doc:"Print raw PRISM CLI output for debugging purposes"
;;

let print_translation_time_flag =
  let open Command.Param in
  flag
    "-translation-time"
    no_arg
    ~doc:"Print time taken for translation of context into PRISM"
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
     and print_ast = print_ast_flag
     and print_translation_time = print_translation_time_flag in
     Prose.output
       ~ctx_file
       ?model_output_file
       ?prop_output_file
       ~print_ast
       ~print_translation_time)
;;

let verify_command =
  Command.basic
    ~summary:
      "Verify probabilistic properties of the given session type context using PRISM."
    (let%map_open.Command ctx_file = ctx_file_flag
     and print_ast = print_ast_flag
     and print_raw_prism = print_raw_prism_flag
     and print_translation_time = print_translation_time_flag in
     Prose.verify ~ctx_file ~print_ast ~print_raw_prism ~print_translation_time)
;;

let command =
  Command.group
    ~summary:
      "Commands to either verify the probilistic session type or output PRISM files for \
       inspection."
    [ "output", output_command; "verify", verify_command ]
;;

let () = Command_unix.run command
