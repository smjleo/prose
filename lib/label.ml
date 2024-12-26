open! Core

module M = struct
  type t =
    { (* TODO: consider using custom types for participants and labels *)
      from_participant : string
    ; to_participant : string
    ; label : string option
    }
  [@@deriving compare, sexp]
end

include M
module LSet = Set.Make (M)

let to_string { from_participant; to_participant; label } =
  let parts = from_participant ^ "_" ^ to_participant in
  match label with
  | None -> parts
  | Some label -> parts ^ "_" ^ label
;;

let in_context_item { Ast.ctx_part; ctx_type } =
  let rec recurse direction participant = function
    | Ast.End -> LSet.empty
    | Mu (_var, stype) -> recurse direction participant stype
    | Variable _var -> LSet.empty
    | Internal { int_part; int_choices } ->
      let each_choice (_p, { Ast.ch_label; ch_sort = _; ch_cont }) =
        let cur =
          { from_participant = participant
          ; to_participant = int_part
          ; label = Some ch_label
          }
        in
        let rest = recurse direction participant ch_cont in
        match direction with
        | `Sending -> Set.union (LSet.singleton cur) rest
        | `Receiving -> rest
      in
      List.map ~f:each_choice int_choices |> LSet.union_list
    | External { ext_part; ext_choices } ->
      let each_choice { Ast.ch_label; ch_sort = _; ch_cont } =
        let cur =
          { from_participant = ext_part
          ; to_participant = participant
          ; label = Some ch_label
          }
        in
        let rest = recurse direction participant ch_cont in
        match direction with
        | `Sending -> rest
        | `Receiving -> Set.union (LSet.singleton cur) rest
      in
      List.map ~f:each_choice ext_choices |> LSet.union_list
  in
  Set.union (recurse `Sending ctx_part ctx_type) (recurse `Receiving ctx_part ctx_type)
;;

let in_context context = List.map ~f:in_context_item context |> LSet.union_list
