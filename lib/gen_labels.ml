open! Core
open Prism

let conjunction = function
  | [] -> BoolConst true
  | c :: cs -> List.fold_left cs ~init:c ~f:(fun accum c -> And (accum, c))
;;

let disjunction = function
  | [] -> BoolConst false
  | [ c ] -> c
  | c :: cs -> List.fold_left cs ~init:c ~f:(fun accum c -> Or (accum, c))
;;

let type_from_context context ~participant =
  List.find_map context ~f:(fun { Ast.ctx_part; ctx_type } ->
    match String.equal ctx_part participant with
    | false -> None
    | true -> Some ctx_type)
;;

(** EBL/EOL(p, q, l, ctx) from the paper. *)
let enabled_states ~direction ~from_participant ~to_participant ~tag context =
  let participant =
    match direction with
    | `Branching -> to_participant
    | `Output -> from_participant
  in
  let rec enabled_states' ~state ty =
    match ty with
    | Ast.End -> Int.Set.empty
    | Mu (_var, t) -> enabled_states' ~state t
    | Variable _var -> Int.Set.empty
    | Internal choice_branches ->
      let rest =
        List.concat_mapi choice_branches ~f:(fun branch_index branch ->
          List.mapi branch ~f:(fun choice_index (_p, { Ast.ch_cont; _ }) ->
            let new_state =
              Type_utils.next_state_internal_nd
                ~state
                ~branch_index
                ~choice_index
                ~choice_branches
            in
            enabled_states' ~state:new_state ch_cont))
        |> Int.Set.union_list
      in
      let all_choices = List.concat_map choice_branches ~f:(List.map ~f:snd) in
      let matches =
        List.exists all_choices ~f:(fun { Ast.ch_part; ch_label; ch_sort; _ } ->
          String.equal ch_part to_participant
          && (match tag with
              | None -> true
              | Some t ->
                Action.Communication.Tag.equal
                  (Action.Communication.Tag.tag ch_label ch_sort)
                  t))
      in
      (match direction, matches with
       | `Branching, _ -> rest
       | _, false -> rest
       | `Output, true -> Set.union rest (Int.Set.singleton state))
    | External ext_choices ->
      let rest =
        List.mapi ext_choices ~f:(fun choice_index { Ast.ch_cont; _ } ->
          let new_state =
            Type_utils.next_state_external ~state ~choice_index ~ext_choices
          in
          enabled_states' ~state:new_state ch_cont)
        |> Int.Set.union_list
      in
      let matches =
        List.exists ext_choices ~f:(fun { Ast.ch_part; ch_label; ch_sort; _ } ->
          String.equal ch_part from_participant
          && (match tag with
              | None -> true
              | Some t ->
                Action.Communication.Tag.equal
                  (Action.Communication.Tag.tag ch_label ch_sort)
                  t))
      in
      (match direction, matches with
       | `Output, _ -> rest
       | _, false -> rest
       | `Branching, true -> Set.union rest (Int.Set.singleton state))
  in
  match type_from_context context ~participant with
  | None -> Int.Set.empty
  | Some ty -> enabled_states' ty ~state:0
;;

let generate context =
  let end_label =
    let clauses =
      List.map context ~f:(fun { Ast.ctx_part; ctx_type } ->
        Eq (Var (StringVar ctx_part), IntConst (Type_utils.state_space ctx_type)))
    in
    { name = End; expr = conjunction clauses }
  in
  let communications = Action.Communication.in_context context in
  let cando_action =
    List.concat_map communications ~f:(fun communication ->
      let { Action.Communication.from_participant; to_participant; tag } =
        communication
      in
      let tag =
        (* Even though unpacking this is unnecessary because [enabled_states] accepts
           a [string option] for label, we add a check here to make sure that
           the label field is actually filled in for the communication, since we
           expect this to always be the case. *)
        match tag with
        | None ->
          error_s
            [%message
              "received empty tag field for communication"
                (communication : Action.Communication.t)]
          |> ok_exn
        | Some tag -> tag
      in
      let eol =
        enabled_states
          ~direction:`Output
          ~from_participant
          ~to_participant
          ~tag:(Some tag)
          context
        |> Set.to_list
      in
      let ebl =
        enabled_states
          ~direction:`Branching
          ~from_participant
          ~to_participant
          ~tag:(Some tag)
          context
        |> Set.to_list
      in
      let output_clauses =
        List.map eol ~f:(fun n -> Eq (Var (StringVar from_participant), IntConst n))
      in
      let branching_clauses =
        List.map ebl ~f:(fun n -> Eq (Var (StringVar to_participant), IntConst n))
      in
      [ { name = Can_do communication; expr = disjunction output_clauses }
      ; { name = Can_do_branch communication; expr = disjunction branching_clauses }
      ])
  in
  let cando_any =
    (* TODO: dedup with above *)
    let unlabelled_communications =
      List.map communications ~f:(fun { from_participant; to_participant; tag = _ } ->
        { Action.Communication.from_participant; to_participant; tag = None })
      |> List.sort ~compare:Action.Communication.compare
      |> List.remove_consecutive_duplicates ~equal:Action.Communication.equal
    in
    List.map unlabelled_communications ~f:(fun communication ->
      let { Action.Communication.from_participant; to_participant; tag = _ } =
        communication
      in
      let eb =
        enabled_states
          ~direction:`Branching
          ~from_participant
          ~to_participant
          ~tag:None
          context
        |> Set.to_list
      in
      let branching_clauses =
        List.map eb ~f:(fun n -> Eq (Var (StringVar to_participant), IntConst n))
      in
      { name = Can_do_branch communication; expr = disjunction branching_clauses })
  in
  List.concat [ [ end_label ]; cando_action; cando_any ]
;;

(** The combined weak-almost-sure-livelock label [WASlivelock(Delta)]: a
    disjunction over the bad global configurations, each a conjunction of
    per-participant [S_p] equalities. Empty (live) ⇒ [false]. *)
let wals_label context =
  let configs = Live.bad_configs context in
  let clauses =
    List.map configs ~f:(fun cfg ->
      conjunction (List.map cfg ~f:(fun (p, n) -> Eq (Var (StringVar p), IntConst n))))
  in
  { name = Wals; expr = disjunction clauses }
;;
