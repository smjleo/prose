open! Core

let rec state_space = function
  | Ast.End -> 0
  | Mu (_var, t) -> state_space t
  | Variable _ -> 0
  | Internal choice_branches ->
    (match choice_branches with
     | [ branch ] -> selection_space branch
     | _ -> 1 + List.sum (module Int) choice_branches ~f:selection_space)
  | External ext_choices ->
    let continuation_space =
      List.fold_left ext_choices ~init:0 ~f:(fun acc { Ast.ch_cont; _ } ->
        acc + state_space ch_cont)
    in
    1 + continuation_space

(* SS of a singleton selection: an entry state, one intermediary state per
   branch, and the continuations. *)
and selection_space branch =
  1
  + List.length branch
  + List.sum (module Int) branch ~f:(fun (_prob, { Ast.ch_cont; _ }) ->
    state_space ch_cont)
;;

let summand_entry_state ~state ~branch_index ~choice_branches =
  match choice_branches with
  | [ _ ] -> state
  | _ ->
    let sum_previous_selection_spaces =
      List.take choice_branches branch_index
      |> List.sum (module Int) ~f:selection_space
    in
    state + 1 + sum_previous_selection_spaces
;;

let intermediate_state_internal ~state ~branch_index ~choice_index ~choice_branches =
  summand_entry_state ~state ~branch_index ~choice_branches + 1 + choice_index
;;

let next_state_internal_nd ~state ~branch_index ~choice_index ~choice_branches =
  let branch = List.nth_exn choice_branches branch_index in
  let sum_previous_state_spaces =
    List.take branch choice_index
    |> List.sum (module Int) ~f:(fun (_p, { Ast.ch_cont; _ }) -> state_space ch_cont)
  in
  summand_entry_state ~state ~branch_index ~choice_branches
  + 1
  + List.length branch
  + sum_previous_state_spaces
;;

let next_state_external ~state ~choice_index ~ext_choices =
  let sum_previous_state_spaces =
    List.take ext_choices choice_index
    |> List.sum (module Int) ~f:(fun { Ast.ch_cont; _ } -> state_space ch_cont)
  in
  state + 1 + sum_previous_state_spaces
;;

let communicates_exn ~context ~from_participant ~to_participant =
  let ty =
    List.find_map_exn context ~f:(fun { Ast.ctx_part; ctx_type } ->
      match String.equal from_participant ctx_part with
      | true -> Some ctx_type
      | false -> None)
  in
  let rec communicates' = function
    | Ast.End -> false
    | Mu (_var, ty) -> communicates' ty
    | Variable _var -> false
    | Internal choice_branches ->
      let all_choices = List.concat choice_branches in
      List.exists all_choices ~f:(fun (_p, { Ast.ch_part; ch_cont; _ }) ->
        String.equal ch_part to_participant || communicates' ch_cont)
    | External ext_choices ->
      List.exists ext_choices ~f:(fun { Ast.ch_part; ch_cont; _ } ->
        String.equal ch_part to_participant || communicates' ch_cont)
  in
  communicates' ty
;;
