open! Core

(** SS(-) in the paper. Denotes the "maximum" state (from 0) this type has,
    not including the very last state which denotes the failure state. *)
val state_space : Ast.session_type -> int

val next_state
  :  direction:[ `Internal | `External ]
  -> state:int
  -> communication:Action.Communication.t
  -> communications:Action.Communication.t list
  -> choices:Ast.choice list
  -> id_map:Action.Id_map.t
  -> int
