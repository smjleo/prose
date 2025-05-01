open! Core

module Communication : sig
  type t =
    { (* TODO: consider using custom types for participants and labels *)
      from_participant : string
    ; to_participant : string
    ; label : string option
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

  (** All the local variables for a participant module. We don't return
      a Prism.var_type because this would introduce a dependency cycle
      (since Prism depends on Action).

      TODO: Lift variable into a separate file? *)
  val local_vars : t -> string -> [ `Int of action * int | `Bool of action ] list
end

val blank : t
val is_blank : t -> bool
val communication : Communication.t -> t
val label : from_participant:string -> to_participant:string -> t
val label_of_communication : Communication.t -> t
val to_string : t -> string
