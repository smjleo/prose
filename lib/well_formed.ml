open! Core

type error =
  | Unbound_variable of string
  | Probabilities_greater_than_one of float

let well_formed_error ~on_error err =
  (* TODO: print type locations *)
  let preamble = "Typing context is not well-formed:" in
  let error_string =
    match err with
    | Unbound_variable ty -> sprintf "%s unbound variable %s\n" preamble ty
    | Probabilities_greater_than_one prob ->
      sprintf "%s probabilities sum to greater than one. Found %f\n" preamble prob
  in
  match on_error with
  | `Print_and_exit ->
    print_endline error_string;
    exit 1
  | `Raise -> error_s [%message error_string] |> ok_exn
  | `Ignore -> ()
;;

let rec check_type ~on_error env = function
  | Ast.End -> ()
  | Mu (var, ty) -> check_type ~on_error (Set.add env var) ty
  | Variable ty ->
    (match Set.exists ~f:(String.equal ty) env with
     | false -> well_formed_error ~on_error (Unbound_variable ty)
     | true -> ())
  | Internal { int_part = _; int_choices } ->
    let sum_probabilities =
      List.fold_left int_choices ~init:0.0 ~f:(fun accum (p, _) -> accum +. p)
    in
    (match Float.( >= ) (sum_probabilities -. 1.0) 1e-6 with
     | true ->
       well_formed_error ~on_error (Probabilities_greater_than_one sum_probabilities)
     | false ->
       List.map int_choices ~f:(fun (_p, c) -> c)
       |> List.iter ~f:(check_choice ~on_error env))
  | External { ext_part = _; ext_choices } ->
    List.iter ext_choices ~f:(check_choice ~on_error env)

and check_choice ~on_error env { ch_label = _; ch_sort = _; ch_cont } =
  check_type ~on_error env ch_cont

and check_context_item ~on_error { Ast.ctx_part = _; ctx_type } =
  check_type ~on_error String.Set.empty ctx_type
;;

let check_context ~on_error = List.iter ~f:(check_context_item ~on_error)
