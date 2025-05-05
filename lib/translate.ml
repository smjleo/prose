open! Core
open Prism

(** The (| - |) function in the paper, which takes a session type and
    produces a list of commands for the PRISM module. *)
let rec translate_type ~id_map ~participant ~state ~state_size ~var_map ty =
  let state_var =
    (* Local variable within the module to keep track of the current state.
       S_p in the paper. *)
    StringVar participant
  in
  let fail_var = StringVar "fail" in
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
  | Internal { int_part; int_choices } ->
    let new_communication label_sort =
      (* Beware, different definition to [new_communication] in [External]! *)
      let tag =
        match label_sort with
        | None -> None
        | Some (label, sort) -> Some (Action.Communication.Tag.tag label sort)
      in
      { Action.Communication.from_participant = participant
      ; to_participant = int_part
      ; tag
      }
    in
    let int_choices =
      (* We sort the internal choice according to their ID, so that the index used to
         denote the next state is canonical. *)
      List.sort int_choices ~compare:(fun (_f1, c1) (_f2, c2) ->
        let id { Ast.ch_label; ch_sort; _ } =
          new_communication (Some (ch_label, ch_sort))
          |> Action.Id_map.id id_map
          |> Option.value_exn
        in
        Int.compare (id c1) (id c2))
    in
    let initial =
      { action = Action.communication (new_communication None)
      ; guard =
          And (Eq (Var state_var, IntConst state), Eq (Var fail_var, BoolConst false))
      ; updates =
          ( 1.0 -. List.sum (module Float) int_choices ~f:(fun (p, _c) -> p)
          , [ IntUpdate (state_var, IntConst (state_size + 1)) ] )
          :: List.mapi int_choices ~f:(fun i (prob, _) ->
            prob, [ IntUpdate (state_var, IntConst (state + i + 1)) ])
      }
    in
    let communications =
      List.map int_choices ~f:(fun (_p, { ch_label; ch_sort; _ }) ->
        new_communication (Some (ch_label, ch_sort)))
    in
    let bald_choices =
      (* Choices without probabilities *)
      List.map int_choices ~f:(fun (_p, c) -> c)
    in
    let choices =
      List.mapi bald_choices ~f:(fun i { ch_label; ch_sort; ch_cont } ->
        let communication = new_communication (Some (ch_label, ch_sort)) in
        let new_state =
          match ch_cont with
          | End -> state_size
          | Variable t -> Map.find_exn var_map t
          | Mu _ | Internal _ | External _ ->
            Type_utils.next_state
              ~direction:`Internal
              ~state
              ~communication
              ~communications
              ~choices:bald_choices
              ~id_map
        in
        { action = Action.communication communication
        ; guard = Eq (Var state_var, IntConst (state + i + 1))
        ; updates = [ 1.0, [ IntUpdate (state_var, IntConst new_state) ] ]
        })
    in
    let continuations =
      List.concat_map bald_choices ~f:(fun { ch_cont; ch_label; ch_sort } ->
        let communication = new_communication (Some (ch_label, ch_sort)) in
        let new_state =
          Type_utils.next_state
            ~direction:`Internal
            ~state
            ~communication
            ~communications
            ~choices:bald_choices
            ~id_map
        in
        translate_type ch_cont ~id_map ~participant ~state:new_state ~state_size ~var_map)
    in
    List.concat [ [ initial ]; choices; continuations ]
  | External { ext_part; ext_choices } ->
    let new_communication label_sort =
      (* Beware, different definition to [new_communication] in [Internal]! *)
      let tag =
        match label_sort with
        | None -> None
        | Some (label, sort) -> Some (Action.Communication.Tag.tag label sort)
      in
      { Action.Communication.from_participant = ext_part
      ; to_participant = participant
      ; tag
      }
    in
    let initial =
      { action =
          Action.communication
            { from_participant = ext_part; to_participant = participant; tag = None }
      ; guard =
          And (Eq (Var state_var, IntConst state), Eq (Var fail_var, BoolConst false))
      ; updates = [ 1.0, [ IntUpdate (state_var, IntConst (state + 1)) ] ]
      }
    in
    let communications =
      List.map ext_choices ~f:(fun { ch_label; ch_sort; _ } ->
        new_communication (Some (ch_label, ch_sort)))
    in
    let choices =
      List.map ext_choices ~f:(fun { ch_cont; ch_label; ch_sort } ->
        let communication = new_communication (Some (ch_label, ch_sort)) in
        let new_state =
          match ch_cont with
          | End -> state_size
          | Variable t -> Map.find_exn var_map t
          | Mu _ | Internal _ | External _ ->
            Type_utils.next_state
              ~direction:`External
              ~state
              ~communication
              ~communications
              ~choices:ext_choices
              ~id_map
        in
        { action = Action.communication communication
        ; guard = Eq (Var state_var, IntConst (state + 1))
        ; updates = [ 1.0, [ IntUpdate (state_var, IntConst new_state) ] ]
        })
    in
    let continuations =
      List.concat_map ext_choices ~f:(fun { ch_cont; ch_label; ch_sort } ->
        let communication = new_communication (Some (ch_label, ch_sort)) in
        let new_state =
          Type_utils.next_state
            ~direction:`External
            ~state
            ~communication
            ~communications
            ~choices:ext_choices
            ~id_map
        in
        translate_type ch_cont ~id_map ~participant ~state:new_state ~state_size ~var_map)
    in
    List.concat [ [ initial ]; choices; continuations ]
;;

let translate_ctx_item ~id_map { Ast.ctx_part; ctx_type } =
  { locals = [ Int (StringVar ctx_part, Type_utils.state_space ctx_type + 1) ]
  ; participant = ctx_part
  ; commands =
      { action = Action.blank
      ; guard =
          Eq (Var (StringVar ctx_part), IntConst (Type_utils.state_space ctx_type + 1))
      ; updates = [ 1.0, [ BoolUpdate (StringVar "fail", BoolConst true) ] ]
      }
      :: translate_type
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
    { action; guard = BoolConst false; updates = [ 1.0, [ dummy_update ] ] }
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

let translate context =
  let id_map = Action.Communication.in_context context |> Action.Id_map.of_list in
  let modules = List.map ~f:(translate_ctx_item ~id_map) context in
  ( { globals = [ Bool (StringVar "fail") ]
    ; modules = closure modules :: modules
    ; labels = Gen_labels.generate ~id_map context
    }
  , Gen_props.generate context )
;;
