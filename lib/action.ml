open! Core

module Communication = struct
  module Tag = struct
    type t =
      { label : string
      ; sort : string
      }
    [@@deriving compare, equal, sexp]

    let tag label sort = { label; sort = Ast.sort_to_string sort }
    let of_label label = tag label Unit
    let to_string { label; sort } = label ^ "_" ^ sort
  end

  module T = struct
    type t =
      { (* TODO: consider using custom types for participants and labels *)
        from_participant : string
      ; to_participant : string
      ; tag : Tag.t option
      }
    [@@deriving compare, equal, sexp]
  end

  include T
  module CSet = Set.Make (T)

  let in_context_item { Ast.ctx_part; ctx_type } =
    let rec recurse direction participant = function
      | Ast.End -> CSet.empty
      | Mu (_var, stype) -> recurse direction participant stype
      | Variable _var -> CSet.empty
      | Internal { int_part; int_choices } ->
        let each_choice (_p, { Ast.ch_label; ch_sort; ch_cont }) =
          let cur =
            { from_participant = participant
            ; to_participant = int_part
            ; tag = Some (Tag.tag ch_label ch_sort)
            }
          in
          let rest = recurse direction participant ch_cont in
          match direction with
          | `Sending -> Set.union (CSet.singleton cur) rest
          | `Receiving -> rest
        in
        List.map ~f:each_choice int_choices |> CSet.union_list
      | External { ext_part; ext_choices } ->
        (* TODO: clean up dup with above *)
        let each_choice { Ast.ch_label; ch_sort; ch_cont } =
          let cur =
            { from_participant = ext_part
            ; to_participant = participant
            ; tag = Some (Tag.tag ch_label ch_sort)
            }
          in
          let rest = recurse direction participant ch_cont in
          match direction with
          | `Sending -> rest
          | `Receiving -> Set.union (CSet.singleton cur) rest
        in
        List.map ~f:each_choice ext_choices |> CSet.union_list
    in
    Set.union (recurse `Sending ctx_part ctx_type) (recurse `Receiving ctx_part ctx_type)
  ;;

  let in_context context =
    List.map ~f:in_context_item context |> CSet.union_list |> Set.to_list
  ;;

  let find_choice { tag; _ } choices =
    match tag with
    | None -> None
    | Some tag ->
      List.find choices ~f:(fun { Ast.ch_label; ch_sort; _ } ->
        Tag.equal (Tag.tag ch_label ch_sort) tag)
  ;;
end

module T = struct
  type t =
    | Blank
    | Communication of Communication.t
  [@@deriving compare, equal, sexp]
end

include T

let blank = Blank

let is_blank = function
  | Blank -> true
  | Communication _ -> false
;;

let communication c = Communication c

let to_string = function
  | Blank -> ""
  | Communication { from_participant; to_participant; tag } ->
    let parts = from_participant ^ "_" ^ to_participant in
    (match tag with
     | None -> parts
     | Some tag -> parts ^ "_" ^ Communication.Tag.to_string tag)
;;

module Id_map = struct
  type nonrec action = t

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

    let of_communication { Communication.from_participant; to_participant; tag = _ } =
      { from_participant; to_participant }
    ;;
  end

  type t =
    { ids : (Key.t, Communication.t list, Key.comparator_witness) Map.t
    ; sending_to : String.Set.t String.Map.t (* from_participant -> to_participant set*)
    }

  let empty = { ids = Map.empty (module Key); sending_to = String.Map.empty }

  let of_list list =
    (* Populate the map by setting the key to the participants in the
       communication. The IDs are simply the indices (1-indexed) of the
       corresponding actions within the list per each (key, value) pair.
       See details of the ID(-) function in the paper. *)
    List.fold_left list ~init:empty ~f:(fun { ids; sending_to } c ->
      let key = Key.of_communication c in
      let ids = Map.add_multi ids ~key ~data:c in
      let sending_to =
        Map.update sending_to key.from_participant ~f:(function
          | None -> String.Set.singleton key.to_participant
          | Some set -> Set.add set key.to_participant)
      in
      { ids; sending_to })
  ;;

  let id { ids; sending_to = _ } communication =
    let key = Key.of_communication communication in
    let open Option.Let_syntax in
    let%bind data = Map.find ids key in
    let%map id =
      (* This is a linear time traversal, but we expect this list to
         be small as it is for a particular (from, to) pair *)
      List.find_mapi data ~f:(fun i c ->
        match Communication.equal c communication with
        | false -> None
        | true -> Some (i + 1))
    in
    id
  ;;

  let communications { ids; sending_to = _ } ~from_participant ~to_participant =
    let key = { Key.from_participant; to_participant } in
    Map.find ids key |> Option.value ~default:[]
  ;;
end

module Map = Map.Make (T)
