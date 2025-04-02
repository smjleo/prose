open! Core

let rec state_space = function
  | Ast.End -> 0
  | Mu (_var, t) -> state_space t
  | Variable _ -> 0
  | Internal { int_part = _; int_choices } ->
    List.fold_left
      ~init:0
      ~f:(fun acc (_prob, { Ast.ch_cont; _ }) -> acc + state_space ch_cont)
      int_choices
    + List.length int_choices
    + 1
  | External { ext_part = _; ext_choices } ->
    List.fold_left
      ~init:0
      ~f:(fun acc { Ast.ch_cont; _ } -> acc + state_space ch_cont)
      ext_choices
    + 2
;;

(** Calculate the big summation in the paper:
      \sum_{i | ID(p::q::l_i) < ID(action)} SS(T_i)
    where communication is p::q::l_j for some j
          communications contains all p::q::l_i
      and choices contains l_i and T_i for all p::q choices *)
let sum_states_until communication ~communications ~choices ~id_map =
  (* TODO: This currently contains a lot of redundant list traversals - probably fine
     since we don't expect a large list, but it'd be nice if it can be made more
     efficient. *)
  let id =
    match Action.Id_map.id id_map communication with
    | None ->
      error_s
        [%message
          "can't find communication in ID map" (communication : Action.Communication.t)]
      |> ok_exn
    | Some id -> id
  in
  List.filter communications ~f:(fun communication ->
    let id' =
      match Action.Id_map.id id_map communication with
      | None ->
        error_s
          [%message
            "can't find communication within provided communications in ID map"
              (communication : Action.Communication.t)
              (communications : Action.Communication.t list)]
        |> ok_exn
      | Some id' -> id'
    in
    id' < id)
  |> List.sum
       (module Int)
       ~f:(fun c ->
         match Action.Communication.find_choice c choices with
         | None ->
           error_s
             [%message
               "can't find choice with communication"
                 (c : Action.Communication.t)
                 (choices : Ast.choice list)]
           |> ok_exn
         | Some { ch_cont; _ } -> state_space ch_cont)
;;

let next_state ~direction ~state ~communication ~communications ~choices ~id_map =
  let delta = sum_states_until communication ~communications ~choices ~id_map in
  (* TODO: dedup calculations with translation function *)
  match direction with
  | `Internal -> state + 1 + List.length choices + delta
  | `External -> state + 2 + delta
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
    | Internal { int_part; int_choices } ->
      String.equal int_part to_participant
      || List.exists int_choices ~f:(fun (_p, { ch_cont; _ }) -> communicates' ch_cont)
    | External { ext_part; ext_choices } ->
      String.equal ext_part to_participant
      || List.exists ext_choices ~f:(fun { ch_cont; _ } -> communicates' ch_cont)
  in
  communicates' ty
;;
