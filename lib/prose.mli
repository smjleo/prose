open! Core

(** Output the PRISM model and property translations of the given context.
    The results are printed to stdout by default, but can be output to a file
    if [model_output_file] or [prop_output_file] are set. *)
val output
  :  ctx_file:string
  -> print_ast:bool
  -> print_translation_time:bool
  -> balance:bool
  -> ?model_output_file:string
  -> ?prop_output_file:string
  -> unit
  -> unit

(** Verify properties of the given context file.
    The results are printed to stdout. *)
val verify
  :  ctx_file:string
  -> print_ast:bool
  -> print_raw_prism:bool
  -> print_translation_time:bool
  -> balance:bool
  -> unit
  -> unit

(** Benchmark the parsing + translation and PRISM invokation runtimes
    for each file in [directory]. The results are printed to stdout.

    [translation_batch_size] controls the batch size per measurement
    for translation. We use a batch size of 1 for PRISM invokations
    since it is slow enough that the overhead of benchmarking is
    insignificant.
*)
val benchmark
  :  iterations:int
  -> directory:string
  -> translation_batch_size:int
  -> unit
  -> unit
