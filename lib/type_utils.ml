open! Core

let rec state_space = function
  | Ast.End -> 0
  | Mu (_var, t) -> state_space t
  | Variable _ -> 0
  | Internal choice_branches ->
    let all_choices = List.concat choice_branches in
    let continuation_space =
      List.fold_left all_choices ~init:0 ~f:(fun acc (_prob, { Ast.ch_cont; _ }) ->
        acc + state_space ch_cont)
    in
    1 + List.length all_choices + continuation_space
  | External ext_choices ->
    let continuation_space =
      List.fold_left ext_choices ~init:0 ~f:(fun acc { Ast.ch_cont; _ } ->
        acc + state_space ch_cont)
    in
    1 + continuation_space
;;

let intermediate_state_offset ~branch_index ~choice_index ~choice_branches =
  let sum_previous_branch_sizes =
    List.take choice_branches branch_index
    |> List.sum (module Int) ~f:List.length
  in
  sum_previous_branch_sizes + choice_index
;;

let next_state_internal_nd ~state ~branch_index ~choice_index ~choice_branches =
  let total_choices =
    List.sum (module Int) choice_branches ~f:List.length
  in
  let sum_previous_state_spaces =
    let previous_branches = List.take choice_branches branch_index in
    let previous_full =
      List.concat previous_branches
      |> List.sum (module Int) ~f:(fun (_p, { Ast.ch_cont; _ }) -> state_space ch_cont)
    in
    let current_branch = List.nth_exn choice_branches branch_index in
    let current_partial =
      List.take current_branch choice_index
      |> List.sum (module Int) ~f:(fun (_p, { Ast.ch_cont; _ }) -> state_space ch_cont)
    in
    previous_full + current_partial
  in
  state + 1 + total_choices + sum_previous_state_spaces
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
