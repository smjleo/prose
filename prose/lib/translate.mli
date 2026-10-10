open! Core

val translate
  :  ?liveness:bool
  -> ?all_props:bool
  -> Ast.context
  -> Prism.model * Psl.annotated_property list
