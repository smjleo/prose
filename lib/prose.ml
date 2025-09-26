open! Core

let dbg_print_s ~print_ast sexp = if print_ast then print_s sexp

let parse lexbuf =
  try Parser.context Lexer.read lexbuf with
  | Parser.Error ->
    let pos = lexbuf.lex_curr_p in
    let line = pos.pos_lnum in
    let column = pos.pos_cnum - pos.pos_bol in
    error_s [%message "Syntax error" (line : int) (column : int)] |> ok_exn
;;

let parse_session lexbuf =
  try Session_parser.session Session_lexer.read lexbuf with
  | Session_parser.Error ->
    let pos = lexbuf.lex_curr_p in
    let line = pos.pos_lnum in
    let column = pos.pos_cnum - pos.pos_bol in
    error_s [%message "Session syntax error" (line : int) (column : int)] |> ok_exn
;;

let parse_and_translate ~on_error ~on_warning ~ctx_file ~balance ~print_ast =
  let dbg_print_s = dbg_print_s ~print_ast in
  let inx = In_channel.create ctx_file in
  let lexbuf = Lexing.from_channel inx in
  lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = ctx_file };
  let is_session_file = String.is_suffix ctx_file ~suffix:".sess" in
  if is_session_file
  then (
    let session = parse_session lexbuf in
    In_channel.close inx;
    let translated, properties = Translate_session.translate session in
    (translated, properties), is_session_file)
  else (
    let context = parse lexbuf in
    In_channel.close inx;
    Well_formed.check_context ~on_error ~on_warning context;
    let translated, properties = Translate.translate context in
    let translated =
      match balance with
      | false -> translated
      | true -> Transform.balance_probabilities translated
    in
    dbg_print_s [%message (context : Ast.context)];
    (translated, properties), is_session_file)
;;

let output_and_return_annotations
      ~ctx_file
      ~print_ast
      ~print_translation_time
      ~on_error
      ~on_warning
      ~balance
      ?model_output_file
      ?prop_output_file
      ?only_annotation
      ()
  =
  let dbg_print_s = dbg_print_s ~print_ast in
  let t0 = Time_float.now () in
  let (translated, properties), is_session_file =
    parse_and_translate ~on_error ~on_warning ~ctx_file ~balance ~print_ast
  in
  let t1 = Time_float.now () in
  let translation_time = Time_float.diff t1 t0 in
  if print_translation_time then print_s [%message (translation_time : Time_float.Span.t)];
  dbg_print_s [%message (translated : Prism.model)];
  Printer.print_model
    ?output_file:model_output_file
    ~use_unbounded_ints:is_session_file
    translated;
  let properties =
    match only_annotation with
    | None -> properties
    | Some only_annotation ->
      List.filter properties ~f:(fun (a, _p) -> Psl.Annotation.equal a only_annotation)
  in
  Printer.print_properties ?output_file:prop_output_file properties;
  let annotations = List.map properties ~f:(fun (a, _p) -> a) in
  annotations
;;

let output
      ~ctx_file
      ~print_ast
      ~print_translation_time
      ~balance
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
    ~balance
    ~on_error:`Print_and_exit
    ~on_warning:`Print
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
    print_endline (Psl.Annotation.to_string a);
    print_endline o)
;;

let with_prism_files
      ~ctx_file
      ~print_ast
      ~print_translation_time
      ~on_error
      ~on_warning
      ~balance
      ~f
      ?only_annotation
      ()
  =
  let model_output_file = Filename_unix.temp_file "model" ".prism" in
  let prop_output_file = Filename_unix.temp_file "properties" ".props" in
  let is_session_file = String.is_suffix ctx_file ~suffix:".sess" in
  let annotations =
    output_and_return_annotations
      ~ctx_file
      ~model_output_file
      ~prop_output_file
      ~print_ast
      ~print_translation_time
      ~on_error
      ~on_warning
      ~balance
      ?only_annotation
      ()
  in
  let res = f ~model_output_file ~prop_output_file ~annotations ~is_session_file in
  Core_unix.remove model_output_file;
  Core_unix.remove prop_output_file;
  res
;;

let verify ~ctx_file ~print_ast ~print_raw_prism ~print_translation_time ~balance () =
  with_prism_files
    ~ctx_file
    ~print_ast
    ~print_translation_time
    ~on_error:`Print_and_exit
    ~on_warning:`Print
    ~balance
    ~f:(fun ~model_output_file ~prop_output_file ~annotations ~is_session_file ->
      let prism_args =
        if is_session_file
        then
          (* Use explicit engine (-ex) for session files to support unbounded integers *)
          [ "-ex"; model_output_file; prop_output_file ]
        else [ model_output_file; prop_output_file ]
      in
      let prism = Core_unix.create_process ~prog:"prism" ~args:prism_args in
      let stdout = Core_unix.in_channel_of_descr prism.stdout in
      let stderr = Core_unix.in_channel_of_descr prism.stderr in
      let lines = In_channel.input_lines stdout in
      let stderr_output = In_channel.input_all stderr in
      if String.length stderr_output <> 0
      then
        error_s [%message "PRISM returned error when verifying" stderr_output] |> ok_exn;
      if print_raw_prism then print_s [%message "Raw PRISM output" (lines : string list)];
      print_output annotations lines)
    ()
;;

let benchmark_translation ~iterations ~ctx_file ~batch_size =
  Microbenchmark.measure
    ~iterations
    ~batch_size
    ~f:(fun () ->
      parse_and_translate
        ~on_error:`Raise
        ~on_warning:`Ignore
        ~balance:false
        ~ctx_file
        ~print_ast:false)
    ()
;;

let benchmark_prism ~annotations ~iterations ~ctx_file =
  List.map annotations ~f:(fun annotation ->
    with_prism_files
      ~ctx_file
      ~print_ast:false
      ~print_translation_time:false
      ~on_error:`Raise
      ~on_warning:`Ignore
      ~balance:false
      ~f:(fun ~model_output_file ~prop_output_file ~annotations:_ ~is_session_file ->
        Microbenchmark.measure
          ~iterations
          ~f:(fun () ->
            let cmd =
              if is_session_file
              then
                sprintf "prism -ex %s %s > /dev/null" model_output_file prop_output_file
              else sprintf "prism %s %s > /dev/null" model_output_file prop_output_file
            in
            Sys_unix.command_exn cmd)
          ())
      ~only_annotation:annotation
      ())
;;

let extract_probability_from_result result_line =
  let result_prefix = "Result: " in
  let result_str = String.drop_prefix result_line (String.length result_prefix) in
  match String.split result_str ~on:' ' with
  | prob_str :: _ -> prob_str
  | [] -> error_s [%message "Could not parse probability from PRISM output"] |> ok_exn
;;

let run_prism_and_get_output ~model_output_file ~prop_output_file ~is_session_file =
  let prism_args =
    if is_session_file
    then [ "-ex"; model_output_file; prop_output_file ]
    else [ model_output_file; prop_output_file ]
  in
  let prism = Core_unix.create_process ~prog:"prism" ~args:prism_args in
  let stdout = Core_unix.in_channel_of_descr prism.stdout in
  let stderr = Core_unix.in_channel_of_descr prism.stderr in
  let lines = In_channel.input_lines stdout in
  let stderr_output = In_channel.input_all stderr in
  if String.length stderr_output <> 0
  then error_s [%message "PRISM returned error when verifying" stderr_output] |> ok_exn;
  parse_prism_output lines
;;

let term_only ~ctx_file () =
  let iterations = 10 in
  let termination_annotation = Psl.Annotation.Probabilisic_termination in
  with_prism_files
    ~ctx_file
    ~print_ast:false
    ~print_translation_time:false
    ~on_error:`Print_and_exit
    ~on_warning:`Ignore
    ~balance:false
    ~f:(fun ~model_output_file ~prop_output_file ~annotations ~is_session_file ->
      let prism_runtimes =
        Microbenchmark.measure
          ~iterations
          ~f:(fun () ->
            let cmd =
              if is_session_file
              then sprintf "prism -ex %s %s > /dev/null" model_output_file prop_output_file
              else sprintf "prism %s %s > /dev/null" model_output_file prop_output_file
            in
            Sys_unix.command_exn cmd)
          ()
      in
      let mean_runtime =
        List.fold prism_runtimes ~init:(Time_float.Span.of_sec 0.0) ~f:Time_float.Span.(+)
        |> fun total -> Time_float.Span.(total / Float.of_int iterations)
      in
      let output = run_prism_and_get_output ~model_output_file ~prop_output_file ~is_session_file in
      let termination_result =
        match List.findi annotations ~f:(fun _i a -> Psl.Annotation.equal a termination_annotation) with
        | None -> error_s [%message "Probabilistic termination property not found"] |> ok_exn
        | Some (index, _) ->
          match List.nth output index with
          | None -> error_s [%message "PRISM output missing termination result"] |> ok_exn
          | Some result_line -> extract_probability_from_result result_line
      in
      printf "%s %f\n" termination_result (Time_float.Span.to_sec mean_runtime))
    ~only_annotation:termination_annotation
    ()
;;

let benchmark ~iterations ~directory ~translation_batch_size ~latex () =
  let annotations = Psl.Annotation.all in
  Display_stats.print_header annotations;
  let filenames = Sys_unix.ls_dir directory |> List.sort ~compare:String.compare in
  let skipped =
    List.filter_map filenames ~f:(fun basename ->
      let ctx_file = Filename.concat directory basename in
      try
        let translation_runtimes =
          benchmark_translation ~iterations ~ctx_file ~batch_size:translation_batch_size
          |> List.map ~f:(fun time ->
            let open Time_float.Span in
            (* TODO: We take the sample mean for now, not sure if we should *)
            time / Float.of_int translation_batch_size)
        in
        let prism_runtimes = benchmark_prism ~annotations ~iterations ~ctx_file in
        Display_stats.print_row basename (translation_runtimes :: prism_runtimes) ~latex;
        None
      with
      | _ -> Some ctx_file)
  in
  print_s [%message "benchmark complete with skipped files" (skipped : string list)]
;;
