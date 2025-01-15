open! Core
open Prism

(** R(-) in the paper. Returns set of all participants in the context. *)
let roles context =
  let rec in_type = function
    | Ast.End -> String.Set.empty
    | Mu (_t, c) -> in_type c
    | Variable _t -> String.Set.empty
    | Internal { int_part; int_choices } ->
      let bald_choices = List.map int_choices ~f:(fun (_p, c) -> c) in
      Set.union (String.Set.singleton int_part) (in_choices bald_choices)
    | External { ext_part; ext_choices } ->
      Set.union (String.Set.singleton ext_part) (in_choices ext_choices)
  and in_choices choices =
    List.map choices ~f:(fun { Ast.ch_cont; _ } -> in_type ch_cont)
    |> String.Set.union_list
  in
  let in_context_item { Ast.ctx_part; ctx_type } =
    Set.union (String.Set.singleton ctx_part) (in_type ctx_type)
  in
  List.map context ~f:in_context_item |> String.Set.union_list
;;

(** CR(-) in the paper. *)
let closed_roles context =
  List.map context ~f:(fun { Ast.ctx_part; _ } -> ctx_part) |> String.Set.of_list
;;

(** OR(-) in the paper. *)
let open_roles context = Set.diff (roles context) (closed_roles context)

(** Generate the closure module, which ensures that any CR <--> OR communication
    does not go through. *)
let closure context =
  let closure_var = StringVar "closure" in
  let dummy_update = BoolUpdate (closure_var, BoolConst false) in
  let dummy_command from_participant to_participant =
    { action = Action.communication { from_participant; to_participant; label = None }
    ; guard = BoolConst false
    ; updates = [ 1.0, [ dummy_update ] ]
    }
  in
  let commands =
    List.cartesian_product
      (Set.to_list (closed_roles context))
      (Set.to_list (open_roles context))
    |> List.map ~f:(fun (c, o) -> [ dummy_command c o; dummy_command o c ])
    |> List.concat
  in
  { locals = [ Bool closure_var ]; participant = "closure"; commands }
;;

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
    let new_communication label =
      { Action.Communication.from_participant = participant
      ; to_participant = int_part
      ; label
      }
    in
    let label_var =
      ActionVar (Action.label ~from_participant:participant ~to_participant:int_part)
    in
    let int_choices =
      (* We sort the internal choice according to their ID, so that the index used to
         denote the next state is canonical. *)
      List.sort int_choices ~compare:(fun (_f1, c1) (_f2, c2) ->
        let id { Ast.ch_label; _ } =
          new_communication (Some ch_label) |> Action.Id_map.id id_map |> Option.value_exn
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
          :: List.mapi int_choices ~f:(fun i (prob, { ch_label; _ }) ->
            let communication =
              { Action.Communication.from_participant = participant
              ; to_participant = int_part
              ; label = Some ch_label
              }
            in
            let id = Action.Id_map.id id_map communication |> Option.value_exn in
            ( prob
            , [ IntUpdate (state_var, IntConst (state + i + 1))
              ; IntUpdate (label_var, IntConst id)
              ] ))
      }
    in
    let communications =
      List.map int_choices ~f:(fun (_p, { ch_label; _ }) ->
        new_communication (Some ch_label))
    in
    let bald_choices =
      (* Choices without probabilities *)
      List.map int_choices ~f:(fun (_p, c) -> c)
    in
    let choices =
      List.mapi bald_choices ~f:(fun i { ch_label; ch_cont; _ } ->
        let communication = new_communication (Some ch_label) in
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
        let communication = new_communication (Some ch_label) in
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
    let initial =
      { action =
          Action.communication
            { from_participant = ext_part; to_participant = participant; label = None }
      ; guard =
          And (Eq (Var state_var, IntConst state), Eq (Var fail_var, BoolConst false))
      ; updates = [ 1.0, [ IntUpdate (state_var, IntConst (state + 1)) ] ]
      }
    in
    let communications =
      Action.Id_map.communications
        id_map
        ~from_participant:ext_part
        ~to_participant:participant
    in
    let present_communications =
      (* Only communications of the form p::q::l_i where l_i is present in ext_choices *)
      List.filter communications ~f:(fun communication ->
        Action.Communication.find_choice communication ext_choices |> Option.is_some)
    in
    let choices =
      List.map communications ~f:(fun communication ->
        match Action.Communication.find_choice communication ext_choices with
        | None ->
          { action = Action.communication communication
          ; guard = BoolConst false
          ; updates = [ 1.0, [ IntUpdate (state_var, IntConst (state + 1)) ] ]
          }
        | Some { ch_cont; _ } ->
          let new_state =
            match ch_cont with
            | End -> state_size
            | Variable t -> Map.find_exn var_map t
            | Mu _ | Internal _ | External _ ->
              Type_utils.next_state
                ~direction:`External
                ~state
                ~communication
                ~communications:present_communications
                ~choices:ext_choices
                ~id_map
          in
          let id = Action.Id_map.id id_map communication |> Option.value_exn in
          let label_var = ActionVar (Action.label_of_communication communication) in
          { action = Action.communication communication
          ; guard =
              And
                (Eq (Var state_var, IntConst (state + 1)), Eq (Var label_var, IntConst id))
          ; updates = [ 1.0, [ IntUpdate (state_var, IntConst new_state) ] ]
          })
    in
    let continuations =
      List.concat_map ext_choices ~f:(fun { ch_cont; ch_label; ch_sort = _ } ->
        let communication =
          { Action.Communication.from_participant = ext_part
          ; to_participant = participant
          ; label = Some ch_label
          }
        in
        let new_state =
          Type_utils.next_state
            ~direction:`External
            ~state
            ~communication
            ~communications:present_communications
            ~choices:ext_choices
            ~id_map
        in
        translate_type ch_cont ~id_map ~participant ~state:new_state ~state_size ~var_map)
    in
    List.concat [ [ initial ]; choices; continuations ]
;;

let translate_ctx_item ~id_map { Ast.ctx_part; ctx_type } =
  let to_var = function
    | `Int (action, max) -> Int (ActionVar action, max)
    | `Bool action -> Bool (ActionVar action)
  in
  { locals =
      Int (StringVar ctx_part, Type_utils.state_space ctx_type + 1)
      :: List.map (Action.Id_map.local_vars id_map ctx_part) ~f:to_var
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

let translate context =
  let id_map = Action.Communication.in_context context |> Action.Id_map.of_list in
  ( { globals = [ Bool (StringVar "fail") ]
    ; modules = closure context :: List.map ~f:(translate_ctx_item ~id_map) context
    ; labels = Gen_labels.generate ~id_map context
    }
  , Gen_props.generate context )
;;
