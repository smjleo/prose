open! Core

(** Checks that the given context is well-formed: probabilities should sum to <= 1,
    and the type should be closed.*)
val check_exn : Ast.context -> unit
