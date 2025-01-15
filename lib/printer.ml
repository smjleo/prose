open! Core
open Prism

let print_variable : type a. Out_channel.t -> a variable -> unit =
  fun ppf -> function
  | StringVar var -> fprintf ppf "%s" var
  | ActionVar var -> fprintf ppf "%s" (Action.to_string var)
;;

let rec print_expr : type a. Out_channel.t -> a expr -> unit =
  fun ppf -> function
  | IntConst n -> fprintf ppf "%d" n
  | BoolConst b -> fprintf ppf "%B" b
  | Var t -> print_variable ppf t
  | Eq (e1, e2) ->
    let fmt =
      match e1, e2 with
      | (And _ | Or _ | Eq _), (And _ | Or _ | Eq _) -> fprintf ppf "(%a)=(%a)"
      | (And _ | Or _ | Eq _), (IntConst _ | BoolConst _ | Var _) -> fprintf ppf "(%a)=%a"
      | (IntConst _ | BoolConst _ | Var _), (And _ | Or _ | Eq _) -> fprintf ppf "%a=(%a)"
      | (IntConst _ | BoolConst _ | Var _), (IntConst _ | BoolConst _ | Var _) ->
        fprintf ppf "%a=%a"
    in
    fmt print_expr e1 print_expr e2
  | And (e1, e2) ->
    let fmt =
      match e1, e2 with
      | And _, And _ -> fprintf ppf "%a & %a"
      | And _, _ -> fprintf ppf "%a & (%a)"
      | _, And _ -> fprintf ppf "(%a) & %a"
      | _ -> fprintf ppf "(%a) & (%a)"
    in
    fmt print_expr e1 print_expr e2
  | Or (e1, e2) ->
    let fmt =
      match e1, e2 with
      | Or _, Or _ -> fprintf ppf "%a | %a"
      | Or _, _ -> fprintf ppf "%a | (%a)"
      | _, Or _ -> fprintf ppf "(%a) | %a"
      | _ -> fprintf ppf "(%a) | (%a)"
    in
    fmt print_expr e1 print_expr e2
;;

let print_list ppf list ~print ~sep =
  match list with
  | [] -> ()
  | x :: xs ->
    print ppf x;
    List.iter xs ~f:(fprintf ppf "%s%a" sep print)
;;

let print_updates ppf updates =
  ignore updates;
  let print ppf update =
    let f (var, expr) = fprintf ppf "(%a'=%a)" print_variable var print_expr expr in
    match update with
    | IntUpdate (v, e) -> f (v, e)
    | BoolUpdate (v, e) -> f (v, e)
  in
  print_list ppf updates ~print ~sep:"&"
;;

let print_command ppf { action; guard; updates } =
  fprintf ppf "[%s] %a -> " (Action.to_string action) print_expr guard;
  let print ppf (prob, updates) =
    (* TODO: %g is nice because it cuts trailing zeroes, but it's not
       nice because it might choose %e instead of %f if it's more
       compact. For now we just pray that the user hasn't put some
       ridiculous probability, but it should be straightforward to
       just write another formatter for floats *)
    fprintf ppf "%g:%a" prob print_updates updates
  in
  print_list ppf updates ~print ~sep:" + ";
  fprintf ppf ";\n"
;;

let print_var ppf = function
  | StringVar str -> fprintf ppf "%s" str
  | ActionVar action -> fprintf ppf "%s" (Action.to_string action)
;;

let print_var_type ppf var ~global =
  let global =
    match global with
    | true -> "global "
    | false -> ""
  in
  match var with
  | Bool var -> fprintf ppf "%s%a : bool init false;\n" global print_var var
  | Int (var, max) -> fprintf ppf "%s%a : [0..%d] init 0;\n" global print_var var max
;;

let print_mod ppf { locals; participant; commands } =
  fprintf ppf "module %s\n" participant;
  List.iter locals ~f:(fprintf ppf "  %a" (print_var_type ~global:false));
  fprintf ppf "\n";
  List.iter commands ~f:(fprintf ppf "  %a" print_command);
  fprintf ppf "endmodule\n"
;;

let print_label_name ppf = function
  | End -> fprintf ppf "end"
  | Deadlock -> fprintf ppf "deadlock"
  | Can_do c -> fprintf ppf "cando_%s" (Action.to_string (Action.communication c))
  | Can_do_branch c ->
    fprintf ppf "cando_%s_branch" (Action.to_string (Action.communication c))
;;

let print_label ppf { name; expr } =
  fprintf ppf "label \"%a\" = %a;\n" print_label_name name print_expr expr
;;

let print_model' ppf { globals; modules; labels } =
  List.iter globals ~f:(print_var_type ppf ~global:true);
  fprintf ppf "\n";
  List.iter modules ~f:(fun m ->
    print_mod ppf m;
    fprintf ppf "\n");
  List.iter labels ~f:(print_label ppf)
;;

let print_with_file ?output_file ~f x =
  let f ppf = f ppf x in
  match output_file with
  | None -> f stdout
  | Some output_file -> Out_channel.with_file output_file ~f
;;

let print_model ?output_file model = print_with_file ?output_file ~f:print_model' model

open Psl

let print_bound ppf = function
  | Exact -> fprintf ppf "min=?"
  | Lt x -> fprintf ppf "<%g" x
  | Le x -> fprintf ppf "<=%g" x
  | Gt x -> fprintf ppf ">%g" x
  | Ge x -> fprintf ppf ">=%g" x
;;

let rec print_path_prop ppf = function
  (* TODO: remove unneeded bracketing *)
  | Label label -> fprintf ppf "\"%a\"" print_label_name label
  | Variable var -> fprintf ppf "%s" var
  | Const b -> fprintf ppf "%B" b
  | And (pp1, pp2) -> fprintf ppf "(%a & %a)" print_path_prop pp1 print_path_prop pp2
  | Or (pp1, pp2) -> fprintf ppf "(%a | %a)" print_path_prop pp1 print_path_prop pp2
  | Implies (pp1, pp2) -> fprintf ppf "(%a => %a)" print_path_prop pp1 print_path_prop pp2
  | G pp -> fprintf ppf "(G %a)" print_path_prop pp
  | F pp -> fprintf ppf "(F %a)" print_path_prop pp
;;

let print_property' ppf = function
  | P (bound, path) -> fprintf ppf "P%a [ %a ]\n" print_bound bound print_path_prop path
;;

let print_property ?output_file property =
  print_with_file ?output_file ~f:print_property' property
;;
