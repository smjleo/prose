open! Core

type context = context_item list [@@deriving sexp]

and context_item =
  { ctx_part : participant
  ; ctx_type : session_type
  }

and participant = string

and session_type =
  | End
  | Mu of variable * session_type
  | Variable of variable
  | Internal of internal_desc
  | External of external_desc

and variable = string

and internal_desc =
  { int_part : participant
  ; int_choices : (probability * choice) list
  }

and external_desc =
  { ext_part : participant
  ; ext_choices : choice list
  }

and probability =
  float (* TODO: probably replace with a custom type later to constrain [0, 1] *)

and choice =
  { ch_label : label
  ; ch_sort : sort
  ; ch_cont : session_type
  }

and label = string

and sort =
  | Unit
  | Int
  | Str
  | Bool (* TODO: need more? *)

let sort_to_string = function
  | Unit -> "unit"
  | Int -> "int"
  | Str -> "str"
  | Bool -> "bool"
;;

type session = session_item list [@@deriving sexp]

and session_item =
  { sess_part : participant
  ; sess_process : process
  }

and process =
  | Nil
  | Mu of variable * process
  | Proc_var of variable
  | Send of send_desc
  | Receive of recv_desc list
  | If_then_else of expr * process * process
  | Flip of probability * process * process

and send_desc =
  { send_part : participant
  ; send_label : label
  ; send_expr : expr option  (* None for synchronisation-only *)
  ; send_cont : process
  }

and recv_desc =
  { recv_part : participant
  ; recv_label : label
  ; recv_var : variable option  (* None for synchronisation-only *)
  ; recv_cont : process
  }

and expr =
  | True
  | False
  | Int of int
  | Expr_var of variable
  | Or of expr * expr
  | Neg of expr
  | Add of expr * expr
  | Mul of expr * expr
  | Succ of expr
  | Less_than of expr * expr
  | Nondeterminism of expr * expr
