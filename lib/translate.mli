open! Core

val translate : ?liveness:bool -> Ast.context -> Prism.model * Psl.annotated_property list
