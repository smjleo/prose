open! Core

val generate : Ast.context -> Prism.label list
(** The ["livelock"] label of the paper (Sec. 6.1): a disjunction over the
    global configurations of the precomputed weak almost-sure livelocked
    region, each a conjunction of per-participant [S_p] equalities. *)
val livelock_label : Ast.context -> Prism.label
