open! Core

(** SS(-) in the paper. Denotes the "maximum" state (from 0) this type has,
    not including the very last state which denotes the failure state. *)
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

(** Calculate the big summation in the paper:
      \sum_{i | ID(p::q::l_i) < ID(action)} SS(T_i)
    where action is p::q::l_j for some j
          actions contains all p::q::l_i
      and choices contains l_i and T_i for all p::q choices *)
let sum_states_until action ~actions ~choices ~id_map =
  (* TODO: This currently contains a lot of redundant list traversals - probably fine
     since we don't expect a large list, but it'd be nice if it can be made more
     efficient. *)
  let id =
    match Action.Id_map.id id_map ~action with
    | None ->
      error_s [%message "can't find action in ID map" (action : Action.t)] |> ok_exn
    | Some id -> id
  in
  List.filter actions ~f:(fun action ->
    let id' =
      match Action.Id_map.id id_map ~action with
      | None ->
        error_s
          [%message
            "can't find action within provided actions in ID map"
              (action : Action.t)
              (actions : Action.t list)]
        |> ok_exn
      | Some id' -> id'
    in
    id' < id)
  |> List.sum
       (module Int)
       ~f:(fun a ->
         match Action.find_choice a choices with
         | None ->
           error_s
             [%message
               "can't find choice with action" (a : Action.t) (choices : Ast.choice list)]
           |> ok_exn
         | Some { ch_cont; _ } -> state_space ch_cont)
;;

(** The (| - |) function in the paper, which takes a session type and
    produces a list of commands for the PRISM module. *)
let rec translate_type ~id_map ~participant ~state ~state_size ~var_map ty =
  let open Prism in
  let state_var =
    (* Local variable within the module to keep track of the current state.
       S_p in the paper. *)
    IntVar participant
  in
  let fail_var = BoolVar "fail" in
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
    let new_action label =
      Action.communication
        ~from_participant:participant
        ~to_participant:int_part
        ?label
        ()
    in
    let label_var =
      ActionVar (Action.label ~from_participant:participant ~to_participant:int_part)
    in
    let initial =
      { action = new_action None
      ; guard =
          And (Eq (Local state_var, IntConst state), Eq (Global fail_var, BoolConst false))
      ; updates =
          ( 1.0 -. List.sum (module Float) int_choices ~f:(fun (p, _c) -> p)
          , [ IntUpdate (state_var, IntConst (state_size + 1)) ] )
          :: List.map int_choices ~f:(fun (prob, { ch_label; _ }) ->
            let action =
              Action.communication
                ~from_participant:participant
                ~to_participant:int_part
                ~label:ch_label
                ()
            in
            let id = Action.Id_map.id id_map ~action |> Option.value_exn in
            ( prob
            , [ IntUpdate (state_var, IntConst (state + id))
              ; IntUpdate (label_var, IntConst id)
              ] ))
      }
    in
    let actions =
      List.map int_choices ~f:(fun (_p, { ch_label; _ }) -> new_action (Some ch_label))
    in
    let bald_choices =
      (* Choices without probabilities *)
      List.map int_choices ~f:(fun (_p, c) -> c)
    in
    let choices =
      List.map bald_choices ~f:(fun { ch_label; ch_cont; _ } ->
        let action = new_action (Some ch_label) in
        let id = Action.Id_map.id id_map ~action |> Option.value_exn in
        let new_state =
          match ch_cont with
          | End -> state_size
          | Variable t -> Map.find_exn var_map t
          | Mu _ | Internal _ | External _ ->
            state
            + 1
            + List.length int_choices
            + sum_states_until action ~actions ~choices:bald_choices ~id_map
        in
        { action
        ; guard = Eq (Local state_var, IntConst (state + id))
        ; updates =
            [ ( 1.0
              , [ IntUpdate (state_var, IntConst new_state)
                ; IntUpdate (label_var, IntConst 0)
                ] )
            ]
        })
    in
    let continuations =
      List.concat_map bald_choices ~f:(fun { ch_cont; ch_label; ch_sort = _ } ->
        let action = new_action (Some ch_label) in
        let new_state =
          state
          + 1
          + List.length int_choices
          + sum_states_until action ~actions ~choices:bald_choices ~id_map
        in
        translate_type ch_cont ~id_map ~participant ~state:new_state ~state_size ~var_map)
    in
    List.concat [ [ initial ]; choices; continuations ]
  | External { ext_part; ext_choices } ->
    let initial =
      { action =
          Action.communication ~from_participant:ext_part ~to_participant:participant ()
      ; guard =
          And (Eq (Local state_var, IntConst state), Eq (Global fail_var, BoolConst false))
      ; updates = [ 1.0, [ IntUpdate (state_var, IntConst (state + 1)) ] ]
      }
    in
    let actions =
      Action.Id_map.actions id_map ~from_participant:ext_part ~to_participant:participant
    in
    let present_actions =
      (* Only actions of the form p::q::l_i where l_i is present in ext_choices *)
      List.filter actions ~f:(fun action ->
        Action.find_choice action ext_choices |> Option.is_some)
    in
    let choices =
      List.map actions ~f:(fun action ->
        match Action.find_choice action ext_choices with
        | None ->
          { action
          ; guard = BoolConst false
          ; updates = [ 1.0, [ IntUpdate (state_var, IntConst (state + 1)) ] ]
          }
        | Some { ch_cont; _ } ->
          let new_state =
            match ch_cont with
            | End -> state_size
            | Variable t -> Map.find_exn var_map t
            | Mu _ | Internal _ | External _ ->
              state
              + 2
              + sum_states_until
                  action
                  ~actions:present_actions
                  ~choices:ext_choices
                  ~id_map
          in
          let id = Action.Id_map.id id_map ~action |> Option.value_exn in
          let label_var = ActionVar (Action.label_of_communication_exn action) in
          { action
          ; guard =
              And
                ( Eq (Local state_var, IntConst (state + 1))
                , Eq (Local label_var, IntConst id) )
          ; updates = [ 1.0, [ IntUpdate (state_var, IntConst new_state) ] ]
          })
    in
    let continuations =
      List.concat_map ext_choices ~f:(fun { ch_cont; ch_label; ch_sort = _ } ->
        let action =
          Action.communication
            ~from_participant:ext_part
            ~to_participant:participant
            ~label:ch_label
            ()
        in
        let new_state =
          state
          + 2
          + sum_states_until action ~actions:present_actions ~choices:ext_choices ~id_map
        in
        translate_type ch_cont ~id_map ~participant ~state:new_state ~state_size ~var_map)
    in
    List.concat [ [ initial ]; choices; continuations ]
;;

let translate_ctx_item ~id_map { Ast.ctx_part; ctx_type } =
  let open Prism in
  { participant = ctx_part
  ; commands =
      { action = Action.blank
      ; guard = Eq (Local (IntVar ctx_part), IntConst (state_space ctx_type + 1))
      ; updates = [ 1.0, [ BoolUpdate (BoolVar "fail", BoolConst true) ] ]
      }
      :: translate_type
           ~id_map
           ~participant:ctx_part
           ~state:0
           ~state_size:(state_space ctx_type)
           ~var_map:String.Map.empty
           ctx_type
  }
;;

let translate context =
  let id_map = Action.in_context context |> Action.Id_map.of_list in
  List.map ~f:(translate_ctx_item ~id_map) context
;;
