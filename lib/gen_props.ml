open! Core
open! Psl

let rec conjunction = function
  | [] -> Const true
  | [ c ] -> c
  | c :: cs -> And (c, conjunction cs)
;;

let deadlock = P (Exact, G (Implies (Label Prism.Deadlock, Label Prism.End)))

let safety context =
  let communications = Action.Communication.in_context context in
  let clauses =
    List.map communications ~f:(fun communication ->
      let unlabelled = { communication with label = None } in
      Implies
        ( And (Label (Prism.Can_do communication), Label (Prism.Can_do_branch unlabelled))
        , Label (Prism.Can_do_branch communication) ))
  in
  P (Exact, G (conjunction clauses))
;;

let generate context = List.concat [ [ deadlock ]; [ safety context ] ]
