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
    let initial =
      { action = Action.communication (new_communication None)
      ; guard =
          And (Eq (Var state_var, IntConst state), Eq (Var fail_var, BoolConst false))
      ; updates =
          ( 1.0 -. List.sum (module Float) int_choices ~f:(fun (p, _c) -> p)
          , [ IntUpdate (state_var, IntConst (state_size + 1)) ] )
          :: List.map int_choices ~f:(fun (prob, { ch_label; _ }) ->
            let communication =
              { Action.Communication.from_participant = participant
              ; to_participant = int_part
              ; label = Some ch_label
              }
            in
            let id = Action.Id_map.id id_map communication |> Option.value_exn in
            ( prob
            , [ IntUpdate (state_var, IntConst (state + id))
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
      List.map bald_choices ~f:(fun { ch_label; ch_cont; _ } ->
        let communication = new_communication (Some ch_label) in
        let id = Action.Id_map.id id_map communication |> Option.value_exn in
        let new_state =
          match ch_cont with
          | End -> state_size
          | Variable t -> Map.find_exn var_map t
          | Mu _ | Internal _ | External _ ->
            state
            + Type_utils.next_state
                ~direction:`Internal
                ~state
                ~communication
                ~communications
                ~choices:bald_choices
                ~id_map
        in
        { action = Action.communication communication
        ; guard = Eq (Var state_var, IntConst (state + id))
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

let labels ~id_map context =
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

let translate context =
  let id_map = Action.Communication.in_context context |> Action.Id_map.of_list in
  ( { globals = [ Bool (StringVar "fail") ]
    ; modules = closure context :: List.map ~f:(translate_ctx_item ~id_map) context
    ; labels = labels ~id_map context
    }
  , Gen_props.generate id_map )
;;
