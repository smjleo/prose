open! Core

(** SS(-) in the paper. Denotes the "maximum" state (from 0) this type has,
    not including the very last state which denotes the failure state. *)
let rec state_space = function
  | Ast.End -> 0
  | Mu (_var, t) -> state_space t
  | Variable _ -> 0
  | Internal { int_part = _; int_choices } ->
    List.fold_left
      ~init:0
      ~f:(fun acc (_prob, { Ast.ch_cont; _ }) -> acc + state_space ch_cont)
      int_choices
    + 2
  | External { ext_part = _; ext_choices } ->
    List.fold_left
      ~init:0
      ~f:(fun acc { Ast.ch_cont; _ } -> acc + state_space ch_cont)
      ext_choices
    + List.length ext_choices
    + 1
;;

(** Calculate the big summation in the paper:
      \sum_{i | ID(p::q::l_i) < ID(label)} SS(T_i)
    where label is p::q::l_j for some j
          labels contains all p::q::l_i
      and choices contains l_i and T_i for all p::q choices *)
let sum_states_until label ~labels ~choices ~id_map =
  (* TODO: This currently contains a lot of redundant list traversals - probably fine
     since we don't expect a large list, but it'd be nice if it can be made more
     efficient. *)
  let id =
    match Label.Id_map.id id_map ~label with
    | None -> error_s [%message "can't find label in ID map" (label : Label.t)] |> ok_exn
    | Some id -> id
  in
  List.filter labels ~f:(fun label ->
    let id' =
      match Label.Id_map.id id_map ~label with
      | None ->
        error_s
          [%message
            "can't find label within provided labels in ID map"
              (label : Label.t)
              (labels : Label.t list)]
        |> ok_exn
      | Some id' -> id'
    in
    id' < id)
  |> List.sum
       (module Int)
       ~f:(fun l ->
         match Label.find_choice l choices with
         | None ->
           error_s
             [%message
               "can't find choice with label" (l : Label.t) (choices : Ast.choice list)]
           |> ok_exn
         | Some { ch_cont; _ } -> state_space ch_cont)
;;

(** The (| - |) function in the paper, which takes a session type and
    produces a list of commands for the PRISM module. *)
let rec translate_type ~id_map ~participant ~state ~state_size ~var_map ty =
  let open Prism in
  let state_var =
    (* Local variable within the module to keep track of the current state.
       S_p in the paper. *)
    IntVar participant
  in
  let fail_var = BoolVar "fail" in
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
  | Internal { int_part; int_choices } -> (* TODO *) []
  | External { ext_part; ext_choices } ->
    let initial =
      { label =
          { Label.from_participant = ext_part
          ; to_participant = participant
          ; label = None
          }
      ; guard =
          And (Eq (Local state_var, IntConst state), Eq (Global fail_var, BoolConst false))
      ; updates = [ 1.0, IntUpdate (state_var, IntConst (state + 1)) ]
      }
    in
    let labels =
      Label.Id_map.labels id_map ~from_participant:ext_part ~to_participant:participant
    in
    let present_labels =
      (* Only labels of the form p::q::l_i where l_i is present in ext_choices *)
      List.filter labels ~f:(fun label ->
        Label.find_choice label ext_choices |> Option.is_some)
    in
    let choices =
      List.map labels ~f:(fun label ->
        match Label.find_choice label ext_choices with
        | None ->
          { label
          ; guard = BoolConst false
          ; updates = [ 1.0, IntUpdate (state_var, IntConst (state + 1)) ]
          }
        | Some { ch_cont; _ } ->
          let new_state =
            match ch_cont with
            | End -> state_size
            | Variable t -> Map.find_exn var_map t
            | Mu _ | Internal _ | External _ ->
              state
              + 2
              + sum_states_until label ~labels:present_labels ~choices:ext_choices ~id_map
          in
          let id = Label.Id_map.id id_map ~label |> Option.value_exn in
          { label
          ; guard =
              And
                ( Eq (Local state_var, IntConst (state + 1))
                , Eq (Local (LabelVar label), IntConst id) )
          ; updates = [ 1.0, IntUpdate (state_var, IntConst new_state) ]
          })
    in
    let continuations =
      List.concat_map ext_choices ~f:(fun { ch_cont; ch_label; ch_sort = _ } ->
        let label =
          { Label.from_participant = ext_part
          ; to_participant = participant
          ; label = Some ch_label
          }
        in
        translate_type
          ch_cont
          ~id_map
          ~participant
          ~state:(sum_states_until label ~labels ~choices:ext_choices ~id_map)
          ~state_size
          ~var_map)
    in
    List.concat [ [ initial ]; choices; continuations ]
;;

let translate_ctx_item ~id_map { Ast.ctx_part; ctx_type } =
  { Prism.participant = ctx_part
  ; commands =
      translate_type
        ~id_map
        ~participant:ctx_part
        ~state:0
        ~state_size:(state_space ctx_type)
        ~var_map:String.Map.empty
        ctx_type
  }
;;

let translate context =
  let id_map = Label.in_context context |> Label.Id_map.of_list in
  List.map ~f:(translate_ctx_item ~id_map) context
;;
