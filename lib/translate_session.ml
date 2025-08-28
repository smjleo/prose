open! Core
open Ast
open Prism

let rec translate_process ~env process =
  let state = Session_env.current_state env in
  let state_var = Session_env.state_var env in
  let at_current_state = Eq (Var state_var, IntConst state) in
  match process with
  | Nil | Proc_var _ -> [], env
  | Mu (var, process) ->
    let env = Session_env.map_variable env ~var in
    translate_process ~env process
  | Send desc -> translate_send ~env desc
  | Receive descs -> translate_recv ~env descs
  | If_then_else (guard, if_true, if_false) ->
    let guard, env = translate_expr ~env guard in
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
  ignore (env, send_part, send_label, send_expr, send_cont);
  failwith "unimplemented"

and translate_recv ~env _descs =
  ignore env;
  failwith "unimplemented"

and translate_expr ~env expr =
  ignore (env, expr);
  failwith "unimplemented"
;;

let translate_session_item { sess_part; sess_process } =
  let env = Session_env.empty ~participant:sess_part in
  let commands, _env = translate_process ~env sess_process in
  { locals = []; participant = sess_part; commands }
;;

let translate session =
  let modules = List.map ~f:translate_session_item session in
  { globals = []; modules; labels = [] }
;;
