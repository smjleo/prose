open! Core

(** SS(-) in the paper. Denotes the "maximum" state (from 0) this type has,
    not including the very last state which denotes the failure state. *)
val state_space : Ast.session_type -> int

(** sel(i) in the paper: the entry state of the [branch_index]-th summand's
    singleton selection. A singleton sum has no summand step, so the entry of
    its selection is the state of the sum itself. *)
val summand_entry_state
  :  state:int
  -> branch_index:int
  -> choice_branches:(Ast.probability * Ast.choice) list list
  -> int

(** The intermediary state a participant moves to after probabilistically
    committing to the [choice_index]-th branch of the [branch_index]-th
    summand. *)
val intermediate_state_internal
  :  state:int
  -> branch_index:int
  -> choice_index:int
  -> choice_branches:(Ast.probability * Ast.choice) list list
  -> int

val next_state_internal_nd
  :  state:int
  -> branch_index:int
  -> choice_index:int
  -> choice_branches:(Ast.probability * Ast.choice) list list
  -> int

val next_state_external
  :  state:int
  -> choice_index:int
  -> ext_choices:Ast.choice list
  -> int

(** Does from_participant try to communicate with to_participant?
    Note p : q & ... and p : q (+) both count as p trying to communicate
    with q (i.e. the direction does not matter) *)
val communicates_exn
  :  context:Ast.context
  -> from_participant:string
  -> to_participant:string
  -> bool
