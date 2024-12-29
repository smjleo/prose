open! Core

(** SS(-) in the paper. Denotes the "maximum" state (from 0) this type has, not including the very last state which denotes the failure state. *)
let rec state_space = function
  | Ast.End -> 0
  | Mu (_var, t) -> state_space t
  | Variable _ -> 0
  | Internal { int_part = _; int_choices } ->
    List.fold_left
      ~init:0
      ~f:(fun acc (_prob, { Ast.ch_cont; _ }) -> acc + state_space ch_cont)
      int_choices
    + 2
  | External { ext_part = _; ext_choices } ->
    List.fold_left
      ~init:0
      ~f:(fun acc { Ast.ch_cont; _ } -> acc + state_space ch_cont)
      ext_choices
    + List.length ext_choices
    + 1
;;
