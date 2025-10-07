open! Core
open Ast
open Prism

(* TODO: this really belongs in [Session_env] *)
let state_utils ~env =
  let state = Session_env.current_state env in
  let state_var = Session_env.state_var env in
  state, state_var, Eq (Var state_var, IntConst state)
;;

(* NOTE: max_int_value is no longer used in session translation because
   we use PRISM explicit engine (-ex) which supports unbounded integers.
   The max_int_value is still defined for compatibility but has no effect.

   TODO: eventually this max int should be an option. *)
let max_int_value = 200

(* How much of each arm to dispense to fail state *)
let upper_bound_discount = 0.1

let maybe_not_fail ~env guard =
  let fail_var = StringVar "fail" in
  match Session_env.upper env with
  | false -> guard
  | true ->
    let not_fail = Neg (Var fail_var) in
    And (not_fail, guard)
;;

let rec translate_process ~env process =
  let _state, state_var, at_current_state = state_utils ~env in
  let fail_var = StringVar "fail" in
  match process with
  | Nil -> [], env
  | Mu (var, process) ->
    let env = Session_env.map_variable env ~var in
    translate_process ~env process
  | Proc_var var ->
    ( [ { action = Action.blank
        ; guard = at_current_state |> maybe_not_fail ~env
        ; updates =
            [ ( Float 1.0
              , [ IntUpdate (state_var, IntConst (Session_env.get_state_for env ~var)) ] )
            ]
        }
      ]
    , Session_env.increment_state env )
  | Send desc -> translate_send ~env desc
  | Receive descs -> translate_recv ~env descs
  | If_then_else (guard, if_true, if_false) ->
    let guard, env = translate_bool_expr ~env guard in
    let env = Session_env.increment_state env in
    let true_state = Session_env.current_state env in
    let if_true, env = translate_process ~env if_true in
    let false_state = Session_env.current_state env in
    let if_false, env = translate_process ~env if_false in
    let true_cmd =
      { action = Action.blank
      ; guard = And (at_current_state, guard) |> maybe_not_fail ~env
      ; updates = [ Float 1.0, [ IntUpdate (state_var, IntConst true_state) ] ]
      }
    in
    let false_cmd =
      { action = Action.blank
      ; guard = And (at_current_state, Neg guard) |> maybe_not_fail ~env
      ; updates = [ Float 1.0, [ IntUpdate (state_var, IntConst false_state) ] ]
      }
    in
    true_cmd :: false_cmd :: (if_true @ if_false), env
  | Flip (p, heads, tails) ->
    let env = Session_env.increment_state env in
    let heads_state = Session_env.current_state env in
    let if_heads, env = translate_process ~env heads in
    let tails_state = Session_env.current_state env in
    let if_tails, env = translate_process ~env tails in
    let updates =
      let heads = IntUpdate (state_var, IntConst heads_state) in
      let tails = IntUpdate (state_var, IntConst tails_state) in
      let fail = BoolUpdate (fail_var, BoolConst true) in
      match Session_env.upper env with
      | false -> [ Float p, [ heads ]; Float (1.0 -. p), [ tails ] ]
      | true ->
        [ Float (p -. upper_bound_discount), [ heads ]
        ; Float (1.0 -. p -. upper_bound_discount), [ tails ]
        ; Float (upper_bound_discount *. 2.0), [ fail ]
        ]
    in
    let flip_cmd =
      { action = Action.blank; guard = at_current_state |> maybe_not_fail ~env; updates }
    in
    flip_cmd :: (if_heads @ if_tails), env

and translate_send ~env { send_part; send_label; send_expr; send_cont } =
  let state, state_var, at_current_state = state_utils ~env in
  let communication_without_tag : Action.Communication.t =
    { from_participant = Session_env.participant env
    ; to_participant = send_part
    ; tag = None
    }
  in
  let communication_with_tag =
    { communication_without_tag with
      tag = Some (Action.Communication.Tag.of_label send_label)
    }
  in
  let action_without_tag = Action.communication communication_without_tag in
  let action_with_tag = Action.communication communication_with_tag in
  let expr, env =
    match send_expr with
    | Some expr ->
      (* TODO: assuming all sending exprs are ints for now *)
      let expr, env = translate_int_expr ~env expr in
      let env =
        Session_env.register_action_var env action_with_tag ~max_value:max_int_value
      in
      Some expr, env
    | None -> None, env
  in
  let handshake =
    { action = action_without_tag
    ; guard = at_current_state |> maybe_not_fail ~env
    ; updates =
        [ ( Float 1.0
          , [ IntUpdate (state_var, IntConst (state + 1)) ]
            @
            match expr with
            | Some expr -> [ IntUpdate (ActionVar action_with_tag, expr) ]
            | None -> [] )
        ]
    }
  in
  let env = Session_env.increment_state env in
  let state, state_var, at_current_state = state_utils ~env in
  let postlude =
    { action = action_with_tag
    ; guard = at_current_state |> maybe_not_fail ~env
    ; updates = [ Float 1.0, [ IntUpdate (state_var, IntConst (state + 1)) ] ]
    }
  in
  let env = Session_env.increment_state env in
  let rest, env = translate_process ~env send_cont in
  handshake :: postlude :: rest, env

and translate_recv ~env descs =
  let _state, state_var, at_current_state = state_utils ~env in
  let env = Session_env.increment_state env in
  (* TODO: sad hack *)
  let { recv_part; _ } = List.hd_exn descs in
  let communication_without_tag : Action.Communication.t =
    { from_participant = recv_part
    ; to_participant = Session_env.participant env
    ; tag = None
    }
  in
  let action_without_tag = Action.communication communication_without_tag in
  let handshake =
    { action = action_without_tag
    ; guard = at_current_state |> maybe_not_fail ~env
    ; updates =
        [ Float 1.0, [ IntUpdate (state_var, IntConst (Session_env.current_state env)) ] ]
    }
  in
  let at_handshake_state =
    Eq (Var (Session_env.state_var env), IntConst (Session_env.current_state env))
  in
  let translate_recv_item ~env { recv_part = recv_part'; recv_label; recv_var; recv_cont }
    =
    assert (String.equal recv_part recv_part');
    let prefixed_var, env =
      match recv_var with
      | Some var ->
        let prefixed_var = Session_env.participant env ^ "_" ^ var in
        let env =
          Session_env.register_variable env ~var:prefixed_var ~max_value:max_int_value
        in
        Some prefixed_var, env
      | None -> None, env
    in
    let communication_with_tag =
      { communication_without_tag with
        tag = Some (Action.Communication.Tag.of_label recv_label)
      }
    in
    let action_with_tag = Action.communication communication_with_tag in
    let postlude =
      { action = action_with_tag
      ; guard = at_handshake_state |> maybe_not_fail ~env
      ; updates =
          [ ( Float 1.0
            , [ IntUpdate (state_var, IntConst (Session_env.current_state env + 1)) ]
              @
              match prefixed_var with
              | Some var -> [ IntUpdate (StringVar var, Var (ActionVar action_with_tag)) ]
              | None -> [] )
          ]
      }
    in
    let env = Session_env.increment_state env in
    let rest, env = translate_process ~env recv_cont in
    postlude :: rest, env
  in
  (* the natural fold so that we iterate in the correct order *)
  let rest, env =
    List.fold_right descs ~init:([], env) ~f:(fun desc (rest, env) ->
      let commands, env = translate_recv_item ~env desc in
      commands @ rest, env)
  in
  handshake :: rest, env

and translate_bool_expr ~env expr =
  match expr with
  | True -> BoolConst true, env
  | False -> BoolConst false, env
  | Expr_var var ->
    let prefixed_var = Session_env.participant env ^ "_" ^ var in
    let env = Session_env.register_variable env ~var:prefixed_var ~max_value:1 in
    Var (StringVar prefixed_var), env
  | Or (e1, e2) ->
    let e1_expr, env = translate_bool_expr ~env e1 in
    let e2_expr, env = translate_bool_expr ~env e2 in
    Or (e1_expr, e2_expr), env
  | Neg e ->
    let e_expr, env = translate_bool_expr ~env e in
    Neg e_expr, env
  | Less_than (e1, e2) ->
    let e1_expr, env = translate_int_expr ~env e1 in
    let e2_expr, env = translate_int_expr ~env e2 in
    Lt (e1_expr, e2_expr), env
  | Int _ | Add _ | Mul _ | Succ _ -> failwith "expected bool, got integer"
  | Nondeterminism _ -> failwith "unimplemented"

and translate_int_expr ~env expr =
  match expr with
  | Int n -> IntConst n, env
  | Expr_var var ->
    let prefixed_var = Session_env.participant env ^ "_" ^ var in
    let env =
      Session_env.register_variable env ~var:prefixed_var ~max_value:max_int_value
    in
    Var (StringVar prefixed_var), env
  | Add (e1, e2) ->
    let e1_expr, env = translate_int_expr ~env e1 in
    let e2_expr, env = translate_int_expr ~env e2 in
    Add (e1_expr, e2_expr), env
  | Mul (e1, e2) ->
    let e1_expr, env = translate_int_expr ~env e1 in
    let e2_expr, env = translate_int_expr ~env e2 in
    Mul (e1_expr, e2_expr), env
  | Succ e ->
    let e_expr, env = translate_int_expr ~env e in
    Add (e_expr, IntConst 1), env
  | True | False | Or _ | Neg _ | Less_than _ -> failwith "expected integer, got bool"
  | Nondeterminism _ -> failwith "unimplemented"
;;

let translate_session_item { sess_part; sess_process } ~upper =
  let env = Session_env.empty ~participant:sess_part ~upper in
  let commands, env = translate_process ~env sess_process in
  let commands =
    match upper with
    | false -> commands
    | true ->
      let fail_var = StringVar "fail" in
      let fail_cmd =
        { action = Action.blank
        ; guard = Eq (Var fail_var, BoolConst true)
        ; updates = [ Float 1.0, [ BoolUpdate (fail_var, BoolConst true) ] ]
        }
      in
      fail_cmd :: commands
  in
  let registered_vars = Session_env.get_registered_variables env in
  let var_locals =
    List.map registered_vars ~f:(fun (var, max_val) -> Int (StringVar var, max_val))
  in
  let state_local = Int (StringVar sess_part, Session_env.current_state env) in
  { locals = state_local :: var_locals; participant = sess_part; commands }
;;

let translate ~upper session =
  let modules = List.map ~f:(translate_session_item ~upper) session in
  let open Psl in
  let properties =
    [ Annotation.Probabilisic_termination, P (Exact, F (Label Deadlock)) ]
  in
  let globals =
    match upper with
    | false -> []
    | true -> [ Bool (StringVar "fail") ]
  in
  { globals; modules; labels = [] }, properties
;;
