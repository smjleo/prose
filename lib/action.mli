open! Core

type t [@@deriving sexp]

(** Stores the mapping between each label and its ID, as well as who each
    participant sends messages to. *)
module Id_map : sig
  type nonrec action = t
  type t

  val of_list : action list -> t
  val id : t -> action:action -> int option

  (** This corresponds to the domid(ID, p, q) function in the paper. *)
  val actions : t -> from_participant:string -> to_participant:string -> action list

  (** All the local variables for a participant module. We don't return
      a Prism.var_type because this would introduce a dependency cycle
      (since Prism depends on Action).

      TODO: Lift variable into a separate file? *)
  val local_vars : t -> string -> [ `Int of action * int | `Bool of action ] list
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

(** If Communication, return (from_participant, to_participant, label) *)
val decompose_exn : t -> string * string * string option

(* TODO: Some type safety guaranteeing that this will always give a communication
   would be nice - GADT? (This would also help get rid of the _exns, hopefully) *)
val communications_in_context : Ast.context -> t list
val find_choice : t -> Ast.choice list -> Ast.choice option
