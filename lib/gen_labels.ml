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

let type_from_context_exn context ~participant =
  List.find_map_exn context ~f:(fun { Ast.ctx_part; ctx_type } ->
    match String.equal ctx_part participant with
    | false -> None
    | true -> Some ctx_type)
;;

let choices_contain_label choices label =
  List.exists choices ~f:(fun { Ast.ch_label; _ } -> String.equal ch_label label)
;;

(** EBL/EOL(p, q, l, ctx) from the paper. *)
let enabled_label_states ~id_map ~direction ~communication context =
  let { Action.Communication.from_participant; to_participant; label } = communication in
  let label =
    match label with
    | None ->
      error_s
        [%message
          "got a communication with empty label" (communication : Action.Communication.t)]
      |> ok_exn
    | Some label -> label
  in
  (* EBL/EOL(q, type, l, n) from the paper. Participants and [label] remain the
     same during recursion, so we omit from the arguments. *)
  let participant =
    match direction with
    | `Branching -> to_participant
    | `Output -> from_participant
  in
  let rec enabled_label_states' ~state ty =
    let communication_rest ~from_participant ~to_participant ~direction choices =
      let communications =
        List.map choices ~f:(fun { Ast.ch_label; _ } ->
          { Action.Communication.from_participant; to_participant; label = Some ch_label })
      in
      List.map choices ~f:(fun { ch_cont; ch_label; ch_sort = _ } ->
        let communication =
          { Action.Communication.from_participant; to_participant; label = Some ch_label }
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
        enabled_label_states' ~state:new_state ch_cont)
      |> Int.Set.union_list
    in
    match ty with
    | Ast.End -> Int.Set.empty
    | Mu (_var, t) -> enabled_label_states' ~state t
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
         , String.equal int_part to_participant
           && choices_contain_label bald_choices label )
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
         , String.equal ext_part from_participant
           && choices_contain_label ext_choices label )
       with
       | `Output, _ -> rest
       | _, false -> rest
       | `Branching, true -> Set.union rest (Int.Set.singleton state))
  in
  enabled_label_states' (type_from_context_exn context ~participant) ~state:0
;;

let generate ~id_map context =
  let end_label =
    let clauses =
      List.map context ~f:(fun { Ast.ctx_part; ctx_type } ->
        Eq (Var (StringVar ctx_part), IntConst (Type_utils.state_space ctx_type)))
    in
    { name = "end"; expr = conjunction clauses }
  in
  let cando_action_labels =
    let communications = Action.Communication.in_context context in
    List.concat_map communications ~f:(fun communication ->
      let { Action.Communication.from_participant; to_participant; _ } = communication in
      let eol =
        enabled_label_states ~id_map ~direction:`Output ~communication context
        |> Set.to_list
      in
      let ebl =
        enabled_label_states ~id_map ~direction:`Branching ~communication context
        |> Set.to_list
      in
      let output_clauses =
        List.map eol ~f:(fun n -> Eq (Var (StringVar from_participant), IntConst n))
      in
      let branching_clauses =
        List.map ebl ~f:(fun n -> Eq (Var (StringVar to_participant), IntConst n))
      in
      let output_name =
        "cando_" ^ Action.to_string (Action.communication communication)
      in
      let branching_name = output_name ^ "_branch" in
      [ { name = output_name; expr = disjunction output_clauses }
      ; { name = branching_name; expr = disjunction branching_clauses }
      ])
  in
  List.concat [ [ end_label ]; cando_action_labels ]
;;
