open! Core
open! Psl

let rec conjunction = function
  | [] -> Const true
  | [ c ] -> c
  | c :: cs -> And (c, conjunction cs)
;;

let deadlock = Label Prism.Deadlock

let deadlock_freedom_lower = P (ExactMin, G (Implies (deadlock, Label Prism.End)))
let deadlock_freedom_upper = P (ExactMax, G (Implies (deadlock, Label Prism.End)))
let termination_lower = P (ExactMin, F deadlock)
let termination_upper = P (ExactMax, F deadlock)

(* Almost-sure liveness (Thm 4.26): a context is live iff the weak-almost-sure-
   livelock region is unreachable. The liveness probability is [G !"wals"]
   ([= 1 - F "wals"]); minimising/maximising over schedulers gives the bounds. *)
let wals = Label Prism.Wals
let liveness_lower = P (ExactMin, G (Not wals))
let liveness_upper = P (ExactMax, G (Not wals))

let safety context =
  let communications = Action.Communication.in_context context in
  let clauses =
    List.map communications ~f:(fun communication ->
      let untagged = { communication with tag = None } in
      Implies
        ( And (Label (Prism.Can_do communication), Label (Prism.Can_do_branch untagged))
        , Label (Prism.Can_do_branch communication) ))
  in
  P (Ge 1.0, G (conjunction clauses))
;;

let generate context =
  [ Annotation.Type_safety, safety context
  ; Annotation.Deadlock_freedom_lower, deadlock_freedom_lower
  ; Annotation.Deadlock_freedom_upper, deadlock_freedom_upper
  ; Annotation.Termination_lower, termination_lower
  ; Annotation.Termination_upper, termination_upper
  ; Annotation.Liveness_lower, liveness_lower
  ; Annotation.Liveness_upper, liveness_upper
  ]
;;
