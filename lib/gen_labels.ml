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

(* TODO: come up with a better name - this is not descriptive of the fact that
   [label] is an [option], and that it returns true when [label] = [None]. *)
let choices_contain_tag choices tag =
  match tag with
  | None -> true
  | Some tag ->
    List.exists choices ~f:(fun { Ast.ch_label; ch_sort; _ } ->
      Action.Communication.Tag.equal (Action.Communication.Tag.tag ch_label ch_sort) tag)
;;

(** EBL/EOL(p, q, l, ctx) from the paper. *)
let enabled_states ~id_map ~direction ~from_participant ~to_participant ~tag context =
  (* EBL/EOL(q, type, l, n) from the paper. Participants and [label] remain the
     same during recursion, so we omit from the arguments. *)
  let participant =
    match direction with
    | `Branching -> to_participant
    | `Output -> from_participant
  in
  let rec enabled_states' ~state ty =
    let communication_rest ~from_participant ~to_participant ~direction choices =
      let communications =
        List.map choices ~f:(fun { Ast.ch_label; ch_sort; _ } ->
          { Action.Communication.from_participant
          ; to_participant
          ; tag = Some (Action.Communication.Tag.tag ch_label ch_sort)
          })
      in
      List.map choices ~f:(fun { ch_cont; ch_label; ch_sort } ->
        let communication =
          { Action.Communication.from_participant
          ; to_participant
          ; tag = Some (Action.Communication.Tag.tag ch_label ch_sort)
          }
        in
        let new_state =
          Type_utils.next_state
            ~direction
            ~state
            ~communication
            ~communications
            ~choices
            ~id_map
        in
        enabled_states' ~state:new_state ch_cont)
      |> Int.Set.union_list
    in
    match ty with
    | Ast.End -> Int.Set.empty
    | Mu (_var, t) -> enabled_states' ~state t
    | Variable _var -> Int.Set.empty
    | Internal { int_part; int_choices } ->
      let bald_choices = List.map int_choices ~f:(fun (_p, c) -> c) in
      let rest =
        communication_rest
          bald_choices
          ~direction:`Internal
          ~from_participant:participant
          ~to_participant:int_part
      in
      (match
         ( direction
         , String.equal int_part to_participant && choices_contain_tag bald_choices tag )
       with
       | `Branching, _ -> rest
       | _, false -> rest
       | `Output, true -> Set.union rest (Int.Set.singleton state))
    | External { ext_part; ext_choices } ->
      let rest =
        communication_rest
          ext_choices
          ~direction:`External
          ~from_participant:ext_part
          ~to_participant:participant
      in
      (match
         ( direction
         , String.equal ext_part from_participant && choices_contain_tag ext_choices tag )
       with
       | `Output, _ -> rest
       | _, false -> rest
       | `Branching, true -> Set.union rest (Int.Set.singleton state))
  in
  match type_from_context context ~participant with
  | None -> Int.Set.empty
  | Some ty -> enabled_states' ty ~state:0
;;

let generate ~id_map context =
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
          ~id_map
          ~direction:`Output
          ~from_participant
          ~to_participant
          ~tag:(Some tag)
          context
        |> Set.to_list
      in
      let ebl =
        enabled_states
          ~id_map
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
          ~id_map
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
