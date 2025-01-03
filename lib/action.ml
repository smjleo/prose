open! Core

module T = struct
  type t =
    | Blank
    | Communication of
        { (* TODO: consider using custom types for participants and labels *)
          from_participant : string
        ; to_participant : string
        ; label : string option
        }
  [@@deriving compare, equal, sexp]
end

include T
module LSet = Set.Make (T)

let blank = Blank

let communication ~from_participant ~to_participant ?label () =
  Communication { from_participant; to_participant; label }
;;

let label ~from_participant ~to_participant =
  (* TODO: Ideally should have a separate variant for this, rather
     than reusing label *)
  Communication { from_participant; to_participant; label = Some "label" }
;;

let label_of_communication_exn t =
  match t with
  | Blank -> error_s [%message "can't convert blank to a label action" (t : t)] |> ok_exn
  | Communication { from_participant; to_participant; _ } ->
    label ~from_participant ~to_participant
;;

let to_string = function
  | Blank -> ""
  | Communication { from_participant; to_participant; label } ->
    let parts = from_participant ^ "_" ^ to_participant in
    (match label with
     | None -> parts
     | Some label -> parts ^ "_" ^ label)
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

    let of_action = function
      | Blank ->
        (* TODO: This is hacky, should clean up later *)
        { from_participant = ""; to_participant = "" }
      | Communication { from_participant; to_participant; _ } ->
        { from_participant; to_participant }
    ;;
  end

  type t =
    { ids : (Key.t, action list, Key.comparator_witness) Map.t
    ; sending_to : String.Set.t String.Map.t (* from_participant -> to_participant set*)
    }

  let empty = { ids = Map.empty (module Key); sending_to = String.Map.empty }

  let of_list list =
    (* Populate the map by setting the key to the participants in the
       action. The IDs are simply the indices (1-indexed) of the
       corresponding actions within the list per each (key, value) pair.
       See details of the ID(-) function in the paper. *)
    List.fold_left list ~init:empty ~f:(fun { ids; sending_to } action ->
      let key = Key.of_action action in
      let ids = Map.add_multi ids ~key ~data:action in
      let sending_to =
        Map.update sending_to key.from_participant ~f:(function
          | None -> String.Set.singleton key.to_participant
          | Some set -> Set.add set key.to_participant)
      in
      { ids; sending_to })
  ;;

  let id { ids; sending_to = _ } ~action =
    let key = Key.of_action action in
    let open Option.Let_syntax in
    let%bind data = Map.find ids key in
    let%map id =
      (* This is a linear time traversal, but we expect this list to
         be small as it is for a particular (from, to) pair *)
      List.find_mapi data ~f:(fun i a ->
        match equal a action with
        | false -> None
        | true -> Some (i + 1))
    in
    id
  ;;

  let actions { ids; sending_to = _ } ~from_participant ~to_participant =
    let key = { Key.from_participant; to_participant } in
    Map.find ids key |> Option.value ~default:[]
  ;;

  let local_vars t p =
    (* We need p::q::label for all q, with maximum values being the number of
       labels (i.e. highest ID) *)
    let qs = Map.find t.sending_to p |> Option.value ~default:String.Set.empty in
    Set.to_list qs
    |> List.map ~f:(fun q ->
      `Int
        ( label ~from_participant:p ~to_participant:q
        , actions t ~from_participant:p ~to_participant:q |> List.length ))
  ;;
end

let in_context_item { Ast.ctx_part; ctx_type } =
  let rec recurse direction participant = function
    | Ast.End -> LSet.empty
    | Mu (_var, stype) -> recurse direction participant stype
    | Variable _var -> LSet.empty
    | Internal { int_part; int_choices } ->
      let each_choice (_p, { Ast.ch_label; ch_sort = _; ch_cont }) =
        let cur =
          Communication
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
          Communication
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

let find_choice t choices =
  match t with
  | Blank -> None
  | Communication { label; _ } ->
    (match label with
     | None -> None
     | Some label ->
       List.find choices ~f:(fun { Ast.ch_label; _ } -> String.equal ch_label label))
;;
