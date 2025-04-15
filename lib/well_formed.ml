open! Core

type error =
  | Unbound_variable of string
  | Probabilities_greater_than_one of float

let well_formed_error err =
  (* TODO: print type locations *)
  printf "Typing context is not well-formed: ";
  (match err with
   | Unbound_variable ty -> printf "unbound variable %s\n" ty
   | Probabilities_greater_than_one prob ->
     printf "probabilities sum to greater than one. Found %f\n" prob);
  exit 1
;;

let rec check_type_exn env = function
  | Ast.End -> ()
  | Mu (var, ty) -> check_type_exn (Set.add env var) ty
  | Variable ty ->
    (match Set.exists ~f:(String.equal ty) env with
     | false -> well_formed_error (Unbound_variable ty)
     | true -> ())
  | Internal { int_part = _; int_choices } ->
    let sum_probabilities =
      List.fold_left int_choices ~init:0.0 ~f:(fun accum (p, _) -> accum +. p)
    in
    (match Float.( >= ) (sum_probabilities -. 1.0) 1e-6 with
     | true -> well_formed_error (Probabilities_greater_than_one sum_probabilities)
     | false ->
       List.map int_choices ~f:(fun (_p, c) -> c) |> List.iter ~f:(check_choice_exn env))
  | External { ext_part = _; ext_choices } ->
    List.iter ext_choices ~f:(check_choice_exn env)

and check_choice_exn env { ch_label = _; ch_sort = _; ch_cont } =
  check_type_exn env ch_cont

and check_context_item_exn { Ast.ctx_part = _; ctx_type } =
  check_type_exn String.Set.empty ctx_type
;;

let check_exn = List.iter ~f:check_context_item_exn
