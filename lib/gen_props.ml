open! Core
open! Psl

let rec conjunction = function
  | [] -> Const true
  | [ c ] -> c
  | c :: cs -> And (c, conjunction cs)
;;

let deadlock = P (Exact, G (Implies (Label Prism.Deadlock, Label Prism.End)))
let termination = P (Exact, F (Label Prism.Deadlock))

let safety context =
  let communications = Action.Communication.in_context context in
  let clauses =
    List.map communications ~f:(fun communication ->
      let unlabelled = { communication with label = None } in
      Implies
        ( And (Label (Prism.Can_do communication), Label (Prism.Can_do_branch unlabelled))
        , Label (Prism.Can_do_branch communication) ))
  in
  P (Ge 1.0, G (conjunction clauses))
;;

let generate context = [ safety context; deadlock; termination ]
