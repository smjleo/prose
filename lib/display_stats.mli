open! Core

val print_header
  :  ?filename_col_width:int
  -> ?data_col_width:int
  -> Psl.Annotation.t list
  -> unit

val print_row
  :  ?filename_col_width:int
  -> ?data_col_width:int
  -> string
  -> Time_float.Span.t list list
  -> latex:bool
  -> unit
