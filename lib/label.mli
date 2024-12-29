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

  val of_list : label list -> t
  val id : t -> label:label -> int option

  (** This corresponds to the domid(ID, p, q) function in the paper. *)
  val labels : t -> from_participant:string -> to_participant:string -> label list
end

val to_string : t -> string
val in_context : Ast.context -> t list
