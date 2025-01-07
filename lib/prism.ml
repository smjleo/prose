open! Core

type model =
  { globals : var_type list
  ; modules : pmodule list
  ; labels : label list
  }
[@@deriving sexp_of]

and var_type =
  | Bool of bool variable
  | Int of int variable * int (* Maximum value. We always assume [0..n] init 0 *)

and pmodule =
  { locals : var_type list
  ; participant : string
  ; commands : command list
  }

and command =
  { action : Action.t
  ; guard : bool expr
  ; updates : (float * update list) list
  }

and _ expr =
  | IntConst : int -> int expr
  | BoolConst : bool -> bool expr
  | Var : 'a variable -> 'a expr
  | Eq : 'a expr * 'a expr -> bool expr
  | And : bool expr * bool expr -> bool expr
  | Or : bool expr * bool expr -> bool expr

and _ variable =
  | StringVar : string -> 'a variable
  | ActionVar : Action.t -> 'a variable

and update =
  | IntUpdate of int variable * int expr
  | BoolUpdate of bool variable * bool expr

and label =
  { name : string
  ; expr : bool expr
  }
