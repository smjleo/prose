open! Core

val output_and_return_annotations
  :  ctx_file:string
  -> print_ast:bool
  -> print_translation_time:bool
  -> ?model_output_file:string
  -> ?prop_output_file:string
  -> unit
  -> string list

val output
  :  ctx_file:string
  -> print_ast:bool
  -> print_translation_time:bool
  -> ?model_output_file:string
  -> ?prop_output_file:string
  -> unit
  -> unit

val verify
  :  ctx_file:string
  -> print_ast:bool
  -> print_raw_prism:bool
  -> print_translation_time:bool
  -> unit
  -> unit
