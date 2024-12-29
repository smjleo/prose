open! Core

type t =
  { (* TODO: consider using custom types for participants and labels *)
    from_participant : string
  ; to_participant : string
  ; label : string option
  }
[@@deriving sexp]

module ID_Map : sig
  type nonrec label = t
  type t

  (** Populate the map by setting the key to the participants in the
      label. The IDs are simply the indices (1-indexed) of the
      corresponding labels within the list per each (key, value) pair.
      See details of the ID(-) function in the paper. *)
  val of_list : label list -> t

  val id : t -> label:label -> int option

  (** This corresponds to the domid(ID, p, q) function in the paper. *)
  val labels : t -> from_participant:string -> to_participant:string -> label list
end

val to_string : t -> string
val in_context : Ast.context -> t list
