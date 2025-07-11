open! Core

(** SS(-) in the paper. Denotes the "maximum" state (from 0) this type has,
    not including the very last state which denotes the failure state. *)
val state_space : Ast.session_type -> int

(** Calculate what the next state should be after a communication. *)
val next_state
  :  direction:[ `Internal | `External ]
  -> state:int
  -> communication:Action.Communication.t
  -> communications:Action.Communication.t list
  -> choices:Ast.choice list
  -> id_map:Action.Id_map.t
  -> int

(** Does from_participant try to communicate with to_participant?
    Note p : q & ... and p : q (+) both count as p trying to communicate
    with q (i.e. the direction does not matter) *)
val communicates_exn
  :  context:Ast.context
  -> from_participant:string
  -> to_participant:string
  -> bool
