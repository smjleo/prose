open! Core

(** Checks that the given context is well-formed: probabilities should sum to <= 1,
    and the type should be closed.*)
val check_context
  :  on_error:[ `Print_and_exit | `Raise | `Ignore ]
  -> on_warning:[ `Print | `Ignore ]
  -> Ast.context
  -> unit
