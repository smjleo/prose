open! Core

type t [@@deriving sexp]

(** Stores the mapping between each label and its ID. *)
module Id_map : sig
  type nonrec action = t
  type t

  val of_list : action list -> t
  val id : t -> action:action -> int option

  (** This corresponds to the domid(ID, p, q) function in the paper. *)
  val actions : t -> from_participant:string -> to_participant:string -> action list
end

val blank : t

val communication
  :  from_participant:string
  -> to_participant:string
  -> ?label:string
  -> unit
  -> t

val label : from_participant:string -> to_participant:string -> t
val label_of_communication_exn : t -> t
val to_string : t -> string
val in_context : Ast.context -> t list
val find_choice : t -> Ast.choice list -> Ast.choice option
