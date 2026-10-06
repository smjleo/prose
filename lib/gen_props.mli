open! Core

val deadlock_freedom_lower : Psl.property
val deadlock_freedom_upper : Psl.property

val generate
  :  ?liveness:bool
  -> ?all_props:bool
  -> Ast.context
  -> Psl.annotated_property list
