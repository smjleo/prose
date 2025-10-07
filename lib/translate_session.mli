open! Core

val translate : upper:bool -> Ast.session -> Prism.model * Psl.annotated_property list
