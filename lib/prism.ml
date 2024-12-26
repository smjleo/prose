open! Core

type model = pmodule list (* TODO: labels in composition?? *)

and pmodule =
  { participant : participant
  ; commands : command list
  }

and participant = string

and command =
  { label : label
  ; guard : int expr
  ; updates : (probability * update) list
  }

and label = string

and _ expr =
  | IntConst : int -> int expr
  | BoolConst : bool -> bool expr
  | IntVar : variable -> int expr
  | BoolVar : variable -> bool expr
  | Eq : 'a expr * 'a expr -> bool expr
  | Add : int expr * int expr -> int expr

and variable = string
and probability = float
and update = variable * var_value

and var_value =
  | Int of int
  | Bool of bool
