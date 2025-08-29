open! Core
open Ast
open Prism

(* TODO: this really belongs in [Session_env] *)
let state_utils ~env =
  let state = Session_env.current_state env in
  let state_var = Session_env.state_var env in
  state, state_var, Eq (Var state_var, IntConst state)
;;

let rec translate_process ~env process =
  let _state, state_var, at_current_state = state_utils ~env in
  match process with
  | Nil | Proc_var _ -> [], env
  | Mu (var, process) ->
    let env = Session_env.map_variable env ~var in
    translate_process ~env process
  | Send desc -> translate_send ~env desc
  | Receive descs -> translate_recv ~env descs
  | If_then_else (guard, if_true, if_false) ->
    let guard = translate_bool_expr ~env guard in
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
  (* TODO: assuming all sending exprs are ints for now *)
  let expr = translate_int_expr ~env send_expr in
  let handshake =
    { action = action_without_tag
    ; guard = at_current_state
    ; updates =
        [ ( Float 1.0
          , [ IntUpdate (state_var, IntConst (state + 1))
            ; IntUpdate (ActionVar action_with_tag, expr)
            ] )
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
  let translate_recv_item ~env { recv_part; recv_label; recv_var; recv_cont } =
    let communication_without_tag : Action.Communication.t =
      { from_participant = recv_part
      ; to_participant = Session_env.participant env
      ; tag = None
      }
    in
    let communication_with_tag =
      { communication_without_tag with
        tag = Some (Action.Communication.Tag.of_label recv_label)
      }
    in
    let action_without_tag = Action.communication communication_without_tag in
    let action_with_tag = Action.communication communication_with_tag in
    let handshake =
      { action = action_without_tag
      ; guard = at_current_state
      ; updates =
          [ Float 1.0, [ IntUpdate (state_var, IntConst (Session_env.current_state env)) ]
          ]
      }
    in
    let postlude =
      { action = action_with_tag
      ; guard =
          Eq (Var (Session_env.state_var env), IntConst (Session_env.current_state env))
      ; updates =
          [ ( Float 1.0
            , [ IntUpdate (state_var, IntConst (Session_env.current_state env + 1))
              ; IntUpdate (StringVar recv_var, Var (ActionVar action_with_tag))
              ] )
          ]
      }
    in
    let env = Session_env.increment_state env in
    let rest, env = translate_process ~env recv_cont in
    handshake :: postlude :: rest, env
  in
  (* the natural fold so that we iterate in the correct order *)
  List.fold_right descs ~init:([], env) ~f:(fun desc (rest, env) ->
    let commands, env = translate_recv_item ~env desc in
    commands @ rest, env)

and translate_bool_expr ~env expr =
  match expr with
  | True -> BoolConst true
  | False -> BoolConst false
  | Expr_var var -> Var (StringVar var)
  | Or (e1, e2) -> Or (translate_bool_expr ~env e1, translate_bool_expr ~env e2)
  | Neg e -> Neg (translate_bool_expr ~env e)
  | Less_than (e1, e2) -> Lt (translate_int_expr ~env e1, translate_int_expr ~env e2)
  | Int _ | Add _ | Succ _ -> failwith "expected bool, got integer"
  | Nondeterminism _ -> failwith "unimplemented"

and translate_int_expr ~env expr =
  match expr with
  | Int n -> IntConst n
  | Expr_var var -> Var (StringVar var)
  | Add (e1, e2) -> Add (translate_int_expr ~env e1, translate_int_expr ~env e2)
  | Succ e -> Add (translate_int_expr ~env e, IntConst 1)
  | True | False | Or _ | Neg _ | Less_than _ -> failwith "expected integer, got bool"
  | Nondeterminism _ -> failwith "unimplemented"
;;

let translate_session_item { sess_part; sess_process } =
  let env = Session_env.empty ~participant:sess_part in
  let commands, env = translate_process ~env sess_process in
  { locals = [ Int (StringVar sess_part, Session_env.current_state env) ]
  ; participant = sess_part
  ; commands
  }
;;

let translate session =
  let modules = List.map ~f:translate_session_item session in
  { globals = []; modules; labels = [] }
;;
