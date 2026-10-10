open! Core

(** The precomputed weak almost-sure livelocked region (paper Def. 6.4,
    computed as [⋃_p Settle_p] by the closure / end-component / fairness-pruning
    procedure of App. E.1): the global configurations from which some
    participant can be kept pending forever by a fair scheduler, with
    probability arbitrarily close to one.

    Each configuration is rendered as a list of [(participant, state)] pairs,
    where [state] is the value of that participant's PRISM state variable
    [S_p]. The result is therefore a disjunction of conjunctions of [S_p]
    equalities, reached with the same maximal probability as
    [WASlivelock(Delta)] (Prop. E.5). *)
val livelock_configs : Ast.context -> (string * int) list list
