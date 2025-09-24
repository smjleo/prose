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
  ; updates : (probability * update list) list
  }

and _ expr =
  | IntConst : int -> int expr
  | BoolConst : bool -> bool expr
  | Var : 'a variable -> 'a expr
  | Eq : 'a expr * 'a expr -> bool expr
  | And : bool expr * bool expr -> bool expr
  | Or : bool expr * bool expr -> bool expr
  | Neg : bool expr -> bool expr
  | Add : int expr * int expr -> int expr
  | Mul : int expr * int expr -> int expr
  | Lt : int expr * int expr -> bool expr

and _ variable =
  | StringVar : string -> 'a variable
  | ActionVar : Action.t -> 'a variable

and update =
  | IntUpdate of int variable * int expr
  | BoolUpdate of bool variable * bool expr

and probability =
  | Float of float
  | Fraction of int * int

and label =
  { name : label_name
  ; expr : bool expr
  }

and label_name =
  | End
  | Deadlock
  | Can_do of Action.Communication.t
  | Can_do_branch of Action.Communication.t
