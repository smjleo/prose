open! Core

type t =
  { (* TODO: consider using custom types for participants and labels *)
    from_participant : string
  ; to_participant : string
  ; label : string option
  }
[@@deriving sexp]

(** Stores the mapping between each label and its ID. *)
module Id_map : sig
  type nonrec action = t
  type t

  val of_list : action list -> t
  val id : t -> action:action -> int option

  (** This corresponds to the domid(ID, p, q) function in the paper. *)
  val actions : t -> from_participant:string -> to_participant:string -> action list
end

val to_string : t -> string
val in_context : Ast.context -> t list
val find_choice : t -> Ast.choice list -> Ast.choice option
