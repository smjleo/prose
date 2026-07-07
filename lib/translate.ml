open! Core
open Prism

(** The {| - |} function in the paper, which takes a session type and
    produces a list of commands for the PRISM module. *)
let rec translate_type ~id_map ~participant ~state ~state_size ~var_map ty =
  let state_var =
    (* Local variable within the module to keep track of the current state.
       S_p in the paper. *)
    StringVar participant
  in
  match ty with
  | Ast.End -> []
  | Mu (var, ty) ->
    translate_type
      ~id_map
      ~participant
      ~state
      ~state_size
      ~var_map:(Map.set var_map ~key:var ~data:state)
      ty
  | Variable _var -> []
  | Internal choice_branches ->
    let summand_commands =
      (* Summand step: for a proper sum (two or more summands), an internal
         transition with probability 1 nondeterministically picks a summand,
         moving to the entry state of its singleton selection. A singleton
         sum is a selection already, so it has no summand step. *)
      match choice_branches with
      | [ _ ] -> []
      | _ ->
        List.mapi choice_branches ~f:(fun branch_index _branch ->
          let entry =
            Type_utils.summand_entry_state ~state ~branch_index ~choice_branches
          in
          { action = Action.blank
          ; guard = Eq (Var state_var, IntConst state)
          ; updates = [ Prism.Float 1.0, [ IntUpdate (state_var, IntConst entry) ] ]
          })
    in
    let commitment_commands =
      (* Commitment step: from the entry state of a singleton selection, an
         internal transition probabilistically picks a branch, moving to its
         intermediary state. *)
      List.mapi choice_branches ~f:(fun branch_index branch ->
        let entry =
          Type_utils.summand_entry_state ~state ~branch_index ~choice_branches
        in
        let choice_updates =
          List.mapi branch ~f:(fun choice_index (prob, _choice) ->
            let intermediate =
              Type_utils.intermediate_state_internal
                ~state
                ~branch_index
                ~choice_index
                ~choice_branches
            in
            Prism.Float prob, [ IntUpdate (state_var, IntConst intermediate) ])
        in
        { action = Action.blank
        ; guard = Eq (Var state_var, IntConst entry)
        ; updates = choice_updates
        })
    in
    let sync_commands =
      List.concat_mapi choice_branches ~f:(fun branch_index branch ->
        List.mapi branch ~f:(fun choice_index (_prob, { Ast.ch_part; ch_label; ch_sort; ch_cont }) ->
          let communication =
            { Action.Communication.from_participant = participant
            ; to_participant = ch_part
            ; tag = Some (Action.Communication.Tag.tag ch_label ch_sort)
            }
          in
          let intermediate =
            Type_utils.intermediate_state_internal
              ~state
              ~branch_index
              ~choice_index
              ~choice_branches
          in
          let new_state =
            match ch_cont with
            | End -> state_size
            | Variable t -> Map.find_exn var_map t
            | Mu _ | Internal _ | External _ ->
              Type_utils.next_state_internal_nd
                ~state
                ~branch_index
                ~choice_index
                ~choice_branches
          in
          { action = Action.communication communication
          ; guard = Eq (Var state_var, IntConst intermediate)
          ; updates = [ Prism.Float 1.0, [ IntUpdate (state_var, IntConst new_state) ] ]
          }))
    in
    let continuations =
      List.concat_mapi choice_branches ~f:(fun branch_index branch ->
        List.concat_mapi branch ~f:(fun choice_index (_prob, { Ast.ch_cont; _ }) ->
          let new_state =
            Type_utils.next_state_internal_nd
              ~state
              ~branch_index
              ~choice_index
              ~choice_branches
          in
          translate_type ch_cont ~id_map ~participant ~state:new_state ~state_size ~var_map))
    in
    List.concat [ summand_commands; commitment_commands; sync_commands; continuations ]
  | External ext_choices ->
    let receive_commands =
      List.mapi ext_choices ~f:(fun choice_index { Ast.ch_part; ch_label; ch_sort; ch_cont } ->
        let communication =
          { Action.Communication.from_participant = ch_part
          ; to_participant = participant
          ; tag = Some (Action.Communication.Tag.tag ch_label ch_sort)
          }
        in
        let new_state =
          match ch_cont with
          | End -> state_size
          | Variable t -> Map.find_exn var_map t
          | Mu _ | Internal _ | External _ ->
            Type_utils.next_state_external ~state ~choice_index ~ext_choices
        in
        { action = Action.communication communication
        ; guard = Eq (Var state_var, IntConst state)
        ; updates = [ Prism.Float 1.0, [ IntUpdate (state_var, IntConst new_state) ] ]
        })
    in
    let continuations =
      List.concat_mapi ext_choices ~f:(fun choice_index { Ast.ch_cont; _ } ->
        let new_state =
          Type_utils.next_state_external ~state ~choice_index ~ext_choices
        in
        translate_type ch_cont ~id_map ~participant ~state:new_state ~state_size ~var_map)
    in
    List.concat [ receive_commands; continuations ]
;;

let translate_ctx_item ~id_map { Ast.ctx_part; ctx_type } =
  { locals = [ Int (StringVar ctx_part, Type_utils.state_space ctx_type) ]
  ; participant = ctx_part
  ; commands =
      translate_type
        ~id_map
        ~participant:ctx_part
        ~state:0
        ~state_size:(Type_utils.state_space ctx_type)
        ~var_map:String.Map.empty
        ctx_type
  }
;;

(** Generate the closure module, which ensures that any isolated transitions
    does not go through. *)
let closure modules =
  let closure_var = StringVar "closure" in
  let dummy_update = BoolUpdate (closure_var, BoolConst false) in
  let disallow action =
    { action; guard = BoolConst false; updates = [ Prism.Float 1.0, [ dummy_update ] ] }
  in
  let get_unique_actions { commands; _ } =
    List.map commands ~f:(fun { action; _ } -> action)
    |> List.sort ~compare:Action.compare
    |> List.remove_consecutive_duplicates ~equal:Action.equal
  in
  let commands = List.map modules ~f:get_unique_actions |> List.concat in
  let actions =
    List.fold_left commands ~init:Action.Map.empty ~f:(fun accum action ->
      Map.update accum action ~f:(function
        | None -> 1
        | Some x -> x + 1))
  in
  let commands =
    Map.to_alist actions
    |> List.filter_map ~f:(fun (action, amount) ->
      match amount with
      | 1 ->
        (* We should block this from synchronising by itself *)
        Some (disallow action)
      | 2 ->
        (* This is fine *)
        None
      | n ->
        (* We shouldn't have any zeros *)
        assert (n > 2);
        (* If more than two participants have this, then this must be an epsilon transition *)
        assert (Action.is_blank action);
        None)
  in
  { locals = [ Bool closure_var ]; participant = "closure"; commands }
;;

let translate ?(liveness = true) ?(all_props = false) context =
  let id_map = Action.Communication.in_context context |> Action.Id_map.of_list in
  let modules = List.map ~f:(translate_ctx_item ~id_map) context in
  let wals_labels = if liveness then [ Gen_labels.wals_label context ] else [] in
  ( { globals = []
    ; modules = closure modules :: modules
    ; labels = Gen_labels.generate context @ wals_labels
    }
  , Gen_props.generate ~liveness ~all_props context )
;;
