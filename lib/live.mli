open! Core

(** The weak-almost-sure-livelock region: the global configurations in which some
    participant can be kept pending forever under a fair scheduler.

    Each configuration is rendered as a list of [(participant, state)] pairs,
    where [state] is the value of that participant's PRISM state variable [S_p].
    The result is therefore a disjunction of conjunctions of [S_p] equalities. *)
val bad_configs : Ast.context -> (string * int) list list
