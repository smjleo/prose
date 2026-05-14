open! Core
open! Psl

let rec conjunction = function
  | [] -> Const true
  | [ c ] -> c
  | c :: cs -> And (c, conjunction cs)
;;

let deadlock = Label Prism.Deadlock

let deadlock_freedom = P (Exact, G (Implies (deadlock, Label Prism.End)))
let termination = P (Exact, F deadlock)

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
  ; Annotation.Probabilistic_deadlock_freedom, deadlock_freedom
  ; Annotation.Probabilisic_termination, termination
  ]
;;
