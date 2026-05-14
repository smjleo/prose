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
  ]
;;
