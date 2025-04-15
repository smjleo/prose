open! Core

let parse lexbuf =
  try Parser.context Lexer.read lexbuf with
  | Parser.Error ->
    let pos = lexbuf.lex_curr_p in
    let line = pos.pos_lnum in
    let column = pos.pos_cnum - pos.pos_bol in
    error_s [%message "Syntax error" (line : int) (column : int)] |> ok_exn
;;

let output_and_return_annotations
      ~ctx_file
      ~print_ast
      ~print_translation_time
      ?model_output_file
      ?prop_output_file
      ()
  =
  let dbg_print_s sexp = if print_ast then print_s sexp in
  let t0 = Time_float.now () in
  let inx = In_channel.create ctx_file in
  let lexbuf = Lexing.from_channel inx in
  lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = ctx_file };
  let context = parse lexbuf in
  dbg_print_s [%message (context : Ast.context)];
  Well_formed.check_exn context;
  let translated, properties = Translate.translate context in
  let t1 = Time_float.now () in
  let translation_time = Time_float.diff t1 t0 in
  dbg_print_s [%message (translated : Prism.model)];
  if print_translation_time then print_s [%message (translation_time : Time_float.Span.t)];
  Printer.print_model ?output_file:model_output_file translated;
  Printer.print_properties ?output_file:prop_output_file properties;
  In_channel.close inx;
  let annotations = List.map properties ~f:(fun (a, _p) -> a) in
  annotations
;;

let output
      ~ctx_file
      ~print_ast
      ~print_translation_time
      ?model_output_file
      ?prop_output_file
      ()
  =
  output_and_return_annotations
    ~ctx_file
    ?model_output_file
    ?prop_output_file
    ~print_ast
    ~print_translation_time
    ()
  |> ignore
;;

let parse_prism_output lines =
  List.fold_left lines ~init:[] ~f:(fun accum line ->
    match String.is_prefix line ~prefix:"Result: " with
    | false -> accum
    | true -> line :: accum)
  |> List.rev
;;

let print_output annotations lines =
  let output = parse_prism_output lines in
  (* I wish [List.iteri2] existed *)
  let annotated_output =
    match List.zip annotations output with
    | Ok x -> x
    | Unequal_lengths ->
      let full_output = String.concat ~sep:"\n" lines in
      error_s
        [%message
          "PRISM output contains an unexpected number of results, likely PRISM returned \
           an error"
            full_output
            (output : string list)]
      |> ok_exn
  in
  List.iteri annotated_output ~f:(fun i (a, o) ->
    if i > 0 then print_endline "";
    print_endline a;
    print_endline o)
;;

let verify ~ctx_file ~print_ast ~print_raw_prism ~print_translation_time () =
  let model_output_file = Filename_unix.temp_file "model" ".prism" in
  let prop_output_file = Filename_unix.temp_file "properties" ".props" in
  let annotations =
    output_and_return_annotations
      ~ctx_file
      ~model_output_file
      ~prop_output_file
      ~print_ast
      ~print_translation_time
      ()
  in
  let prism =
    Core_unix.create_process ~prog:"prism" ~args:[ model_output_file; prop_output_file ]
  in
  let stdout = Core_unix.in_channel_of_descr prism.stdout in
  let stderr = Core_unix.in_channel_of_descr prism.stderr in
  let lines = In_channel.input_lines stdout in
  let stderr_output = In_channel.input_all stderr in
  if String.length stderr_output <> 0
  then error_s [%message "PRISM returned error when verifying" stderr_output] |> ok_exn;
  if print_raw_prism then print_s [%message "Raw PRISM output" (lines : string list)];
  Core_unix.remove model_output_file;
  Core_unix.remove prop_output_file;
  print_output annotations lines
;;
