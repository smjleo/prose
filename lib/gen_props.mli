open! Core

val generate
  :  ?liveness:bool
  -> ?all_props:bool
  -> Ast.context
  -> Psl.annotated_property list
