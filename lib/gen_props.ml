open! Core
open! Psl

let rec conjunction = function
  | [] -> Const true
  | [ c ] -> c
  | c :: cs -> And (c, conjunction cs)
;;

(* Helpers *)
let fail = Variable "fail"
let non_failing_path = P (Exact, G (Not fail))
let normalise prop = Divide (prop, non_failing_path)
let deadlock = Label Prism.Deadlock
let non_fail_deadlock = And (Label Prism.Deadlock, Not fail)

(* Properties *)
let deadlock_freedom = P (Exact, G (Implies (deadlock, Label Prism.End)))
let normalised_deadlock_freedom = normalise deadlock_freedom
let termination = P (Exact, F non_fail_deadlock)
let normalised_termination = normalise termination

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
  List.zip_exn
    Annotation.all
    [ safety context
    ; deadlock_freedom
    ; normalised_deadlock_freedom
    ; termination
    ; normalised_termination
    ]
;;
