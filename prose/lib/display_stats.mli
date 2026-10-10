open! Core

(** Output format for benchmark tables. [Plain] is a fixed-width text table,
    [Latex] emits rows for a LaTeX [tabular] environment, and [Markdown]
    emits a GitHub-flavoured Markdown table. *)
module Format : sig
  type t =
    | Plain
    | Latex
    | Markdown
end

val print_header
  :  ?filename_col_width:int
  -> ?data_col_width:int
  -> Psl.Annotation.t list
  -> format:Format.t
  -> unit

val print_row
  :  ?filename_col_width:int
  -> ?data_col_width:int
  -> string
  -> Time_float.Span.t list list
  -> format:Format.t
  -> unit

(** Size of a PRISM model as reported by PRISM after model construction.
    [choices] is only reported for MDPs. *)
type model_size =
  { states : int
  ; transitions : int
  ; choices : int option
  }

val print_size_header
  :  ?filename_col_width:int
  -> ?data_col_width:int
  -> format:Format.t
  -> unit
  -> unit

val print_size_row
  :  ?filename_col_width:int
  -> ?data_col_width:int
  -> string
  -> model_size
  -> format:Format.t
  -> unit
