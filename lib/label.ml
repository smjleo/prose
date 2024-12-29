open! Core

module T = struct
  type t =
    { (* TODO: consider using custom types for participants and labels *)
      from_participant : string
    ; to_participant : string
    ; label : string option
    }
  [@@deriving compare, equal, sexp]
end

include T
module LSet = Set.Make (T)

module ID_Map = struct
  type nonrec label = t

  module Key = struct
    module KT = struct
      type t =
        { from_participant : string
        ; to_participant : string
        }
      [@@deriving compare, sexp]
    end

    include KT
    include Comparator.Make (KT)

    let of_label { T.from_participant; to_participant; _ } =
      { from_participant; to_participant }
    ;;
  end

  type t = (Key.t, label list, Key.comparator_witness) Map.t

  let of_list list =
    List.fold_left
      list
      ~init:(Map.empty (module Key))
      ~f:(fun accum label ->
        let key = Key.of_label label in
        Map.add_multi accum ~key ~data:label)
  ;;

  let id t ~label =
    let key = Key.of_label label in
    let open Option.Let_syntax in
    let%bind data = Map.find t key in
    let%map id =
      (* This is a linear time traversal, but we expect this list to
         be small as it is for a particular (from, to) pair *)
      List.find_mapi data ~f:(fun i l ->
        match equal l label with
        | false -> None
        | true -> Some (i + 1))
    in
    id
  ;;

  let labels t ~from_participant ~to_participant =
    let key = { Key.from_participant; to_participant } in
    Map.find t key |> Option.value ~default:[]
  ;;
end

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
      (* TODO: clean up dup with above *)
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

let in_context context =
  List.map ~f:in_context_item context |> LSet.union_list |> Set.to_list
;;
