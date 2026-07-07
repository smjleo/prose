open! Core

type error =
  | Unbound_variable of string
  | Probabilities_not_one of float

let well_formed_error ~on_error err =
  let preamble = "Typing context is not well-formed:" in
  let error_string =
    match err with
    | Unbound_variable ty -> sprintf "%s unbound variable %s\n" preamble ty
    | Probabilities_not_one prob ->
      sprintf "%s probabilities must sum to 1.0. Found %f\n" preamble prob
  in
  match on_error with
  | `Print_and_exit ->
    print_endline error_string;
    exit 1
  | `Raise -> error_s [%message error_string] |> ok_exn
  | `Ignore -> ()
;;

type warning = Zero_probability

let well_formed_warning ~on_warning warning =
  let preamble = "Warning:" in
  let warning_string =
    match warning with
    | Zero_probability ->
      sprintf "%s found zero-probability in context.\n" preamble
  in
  match on_warning with
  | `Print -> print_endline warning_string
  | `Ignore -> ()
;;

let rec check_type ~on_error ~on_warning env = function
  | Ast.End -> ()
  | Mu (var, ty) -> check_type ~on_error ~on_warning (Set.add env var) ty
  | Variable ty ->
    (match Set.exists ~f:(String.equal ty) env with
     | false -> well_formed_error ~on_error (Unbound_variable ty)
     | true -> ())
  | Internal choice_branches ->
    List.iter choice_branches ~f:(fun branch ->
      let sum_probabilities =
        List.fold_left branch ~init:0.0 ~f:(fun accum (p, _) ->
          if Float.equal p Float.zero
          then well_formed_warning ~on_warning Zero_probability;
          accum +. p)
      in
      if Float.( > ) (Float.abs (sum_probabilities -. 1.0)) 1e-6
      then well_formed_error ~on_error (Probabilities_not_one sum_probabilities));
    List.concat_map choice_branches ~f:(List.map ~f:snd)
    |> List.iter ~f:(check_choice ~on_error ~on_warning env)
  | External ext_choices ->
    List.iter ext_choices ~f:(check_choice ~on_error ~on_warning env)

and check_choice ~on_error ~on_warning env { ch_part = _; ch_label = _; ch_sort = _; ch_cont } =
  check_type ~on_error ~on_warning env ch_cont

and check_context_item ~on_error ~on_warning { Ast.ctx_part = _; ctx_type } =
  check_type ~on_error ~on_warning String.Set.empty ctx_type
;;

let check_context ~on_error ~on_warning =
  List.iter ~f:(check_context_item ~on_error ~on_warning)
;;
