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

let balance_flag =
  let open Command.Param in
  flag
    "-balance"
    no_arg
    ~doc:
      "Balance probabilities of selection to all have equal probability. This should be \
       used when checking non-probabilistic properties (e.g. safety) of typing contexts \
       that contain zero-probability transitions."
;;

let upper_flag =
  let open Command.Param in
  flag "-upper" no_arg ~doc:""
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
     and print_translation_time = print_translation_time_flag
     and balance = balance_flag
     and upper = upper_flag in
     Prose.output
       ~ctx_file
       ?model_output_file
       ?prop_output_file
       ~print_ast
       ~print_translation_time
       ~balance
       ~upper)
;;

let benchmark_command =
  Command.basic
    ~summary:
      "Benchmark the parsing + translation and PRISM invokation runtimes for each file \
       in the given directory."
    (let%map_open.Command directory = anon ("directory" %: string)
     and iterations =
       flag
         "-n"
         (optional_with_default 30 int)
         ~doc:"int How many times to run each measurement (default: 30)"
     and translation_batch_size =
       flag
         "-tb"
         (optional_with_default
            (* Apparently [Time_float.now] takes about 800ns of overhead, and rough testing shows
              parsing + translating together takes in the order of 100ns. Using 100 iterations
              should help mitigate the overhead *)
            100
            int)
         ~doc:"int Batch size for translation benchmarking measurements (default: 100)"
     and latex = flag "-latex" no_arg ~doc:"bool Output table in LaTeX format" in
     Prose.benchmark ~iterations ~directory ~translation_batch_size ~latex)
;;

let term_only_flag =
  let open Command.Param in
  flag
    "-term-only"
    no_arg
    ~doc:" Only check probabilistic termination and output probability and verification time"
;;

let verify_command =
  Command.basic
    ~summary:
      "Verify probabilistic properties of the given session type context using PRISM."
    (let%map_open.Command ctx_file = ctx_file_flag
     and print_ast = print_ast_flag
     and print_raw_prism = print_raw_prism_flag
     and print_translation_time = print_translation_time_flag
     and balance = balance_flag
     and term_only = term_only_flag
     and upper = upper_flag in
     if term_only
     then Prose.term_only ~ctx_file ~upper
     else Prose.verify ~ctx_file ~print_ast ~print_raw_prism ~print_translation_time ~balance ~upper)
;;

let command =
  Command.group
    ~summary:
      "Commands to either verify the probilistic session type or output PRISM files for \
       inspection."
    [ "output", output_command; "verify", verify_command; "benchmark", benchmark_command ]
;;

let () = Command_unix.run command
