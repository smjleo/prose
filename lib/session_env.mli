open! Core

type t

val empty : participant:string -> t
val current_state : t -> int
val increment_state : t -> t
val map_variable : t -> var:string -> t
val get_state_for : t -> var:string -> int
val participant : t -> string
val state_var : t -> int Prism.variable
