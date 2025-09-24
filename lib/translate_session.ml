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

let rec translate_process ~env process =
  let _state, state_var, at_current_state = state_utils ~env in
  match process with
  | Nil -> [], env
  | Mu (var, process) ->
    let env = Session_env.map_variable env ~var in
    translate_process ~env process
  | Proc_var var ->
    ( [ { action = Action.blank
        ; guard = at_current_state
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
      ; guard = And (at_current_state, guard)
      ; updates = [ Float 1.0, [ IntUpdate (state_var, IntConst true_state) ] ]
      }
    in
    let false_cmd =
      { action = Action.blank
      ; guard = And (at_current_state, Neg guard)
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
    let flip_cmd =
      { action = Action.blank
      ; guard = at_current_state
      ; updates =
          [ Float p, [ IntUpdate (state_var, IntConst heads_state) ]
          ; Float (1.0 -. p), [ IntUpdate (state_var, IntConst tails_state) ]
          ]
      }
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
    ; guard = at_current_state
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
    ; guard = at_current_state
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
    ; guard = at_current_state
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
      ; guard = at_handshake_state
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

let translate_session_item { sess_part; sess_process } =
  let env = Session_env.empty ~participant:sess_part in
  let commands, env = translate_process ~env sess_process in
  let registered_vars = Session_env.get_registered_variables env in
  let var_locals =
    List.map registered_vars ~f:(fun (var, max_val) -> Int (StringVar var, max_val))
  in
  let state_local = Int (StringVar sess_part, Session_env.current_state env) in
  { locals = state_local :: var_locals; participant = sess_part; commands }
;;

let translate session =
  let modules = List.map ~f:translate_session_item session in
  let open Psl in
  let properties =
    [ Annotation.Probabilisic_termination, P (Exact, F (Label Deadlock)) ]
  in
  { globals = []; modules; labels = [] }, properties
;;
