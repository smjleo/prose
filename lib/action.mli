open! Core

module Communication : sig
  (** A label-sort pair, so that usages of the same label with different sorts
      essentially count as different labels. *)
  module Tag : sig
    type t [@@deriving compare, equal, sexp]

    val tag : string -> Ast.sort -> t

    (* TODO: hack, remove later *)
    val of_label : string -> t
    val to_string : t -> string
  end

  type t =
    { (* TODO: consider using custom types for participants and labels *)
      from_participant : string
    ; to_participant : string
    ; tag : Tag.t option
    }
  [@@deriving compare, equal, sexp]

  val in_context : Ast.context -> t list
  val find_choice : t -> Ast.choice list -> Ast.choice option
end

type t [@@deriving compare, equal, sexp]

module Map : Map.S with type Key.t = t

(** Stores the mapping between each label and its ID, as well as who each
    participant sends messages to. *)
module Id_map : sig
  type nonrec action = t
  type t

  val of_list : Communication.t list -> t
  val id : t -> Communication.t -> int option

  (** This corresponds to the domid(ID, p, q) function in the paper. *)
  val communications
    :  t
    -> from_participant:string
    -> to_participant:string
    -> Communication.t list
end

val blank : t
val is_blank : t -> bool
val communication : Communication.t -> t
val to_string : t -> string
