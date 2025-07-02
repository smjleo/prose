open! Core

module Annotation : sig
  type t =
    | Type_safety
    | Probabilistic_deadlock_freedom
    | Normalised_probabilistic_deadlock_freedom
    | Probabilisic_termination
    | Normalised_probabilistic_termination
  [@@deriving equal, sexp_of]

  val all : t list
  val to_string : t -> string
end

type annotated_property = Annotation.t * property

and property =
  | P of bound * path_property
  | Divide of property * property

and bound =
  | Exact
  | Lt of float
  | Le of float
  | Gt of float
  | Ge of float

and path_property =
  | Label of Prism.label_name
  | Variable of string
  | Const of bool
  | And of path_property * path_property
  | Or of path_property * path_property
  | Not of path_property
  | Implies of path_property * path_property
  | G of path_property (** Globally / always *)
  | F of path_property (** Future / eventually *)
