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
