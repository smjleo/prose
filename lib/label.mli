open! Core

module M : sig
  type t =
    { (* TODO: consider using custom types for participants and labels *)
      from_participant : string
    ; to_participant : string
    ; label : string option
    }
  [@@deriving compare, sexp]
end

include module type of M
module LSet : module type of Set.Make (M)

val to_string : t -> string
val in_context : Ast.context -> LSet.t
