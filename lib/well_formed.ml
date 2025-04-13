open! Core

let rec check_type_exn env = function
  | Ast.End -> ()
  | Mu (var, ty) -> check_type_exn (Set.add env var) ty
  | Variable ty ->
    (match Set.exists ~f:(String.equal ty) env with
     | false -> error_s [%message "unbound variable" ty] |> ok_exn
     | true -> ())
  | Internal { int_part = _; int_choices } ->
    let sum_probabilities =
      List.fold_left int_choices ~init:0.0 ~f:(fun accum (p, _) -> accum +. p)
    in
    (match Float.( >= ) (sum_probabilities -. 1.0) 1e-6 with
     | true ->
       error_s
         [%message "probabilities sum to more than one" (sum_probabilities : Float.t)]
       |> ok_exn
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
