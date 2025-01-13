open! Core
open! Psl

let deadlock = P (Exact, G (Implies (Label "noreduction", Label "end")))

let generate id_map =
  ignore id_map;
  List.concat [ [ P (Exact, And (Label "test1", Label "test2")) ]; [ deadlock ] ]
;;
