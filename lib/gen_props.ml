open! Core
open! Psl

let rec conjunction = function
  | [] -> Const true
  | [ c ] -> c
  | c :: cs -> And (c, conjunction cs)
;;

let noreduction = Or (Label Prism.Deadlock, Variable "fail")
let deadlock_freedom = P (Exact, G (Implies (noreduction, Label Prism.End)))

let normalised_deadlock_freedom =
  Divide (deadlock_freedom, P (Exact, G (Not (Variable "fail"))))
;;

let termination = P (Exact, F noreduction)

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
    [ safety context; deadlock_freedom; normalised_deadlock_freedom; termination ]
;;
