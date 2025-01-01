open! Core

type model = pmodule list (* TODO: labels in composition?? *)

and pmodule =
  { participant : participant
  ; commands : command list
  }

and participant = string

and command =
  { label : Label.t
  ; guard : bool expr
  ; updates : (probability * update) list
  }

and _ expr =
  | IntConst : int -> int expr
  | BoolConst : bool -> bool expr
  | Local : 'a variable -> 'a expr
  | Global : 'a variable -> 'a expr
  | Eq : 'a expr * 'a expr -> bool expr
  | Add : int expr * int expr -> int expr
  | And : bool expr * bool expr -> bool expr

and _ variable =
  | IntVar : string -> int variable
  | LabelVar : Label.t -> int variable
  | BoolVar : string -> bool variable

and probability = float

and update =
  | IntUpdate of int variable * int expr
  | BoolUpdate of bool variable * bool expr
