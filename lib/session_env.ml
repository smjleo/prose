open! Core

type t =
  { current_state : int
  ; proc_vars : int String.Map.t
  ; participant : string
  ; state_var : int Prism.variable
  ; registered_vars : int String.Map.t
  }

let empty ~participant =
  { current_state = 0
  ; proc_vars = String.Map.empty
  ; participant
  ; state_var = StringVar participant
  ; registered_vars = String.Map.empty
  }
;;

let current_state t = t.current_state
let increment_state t = { t with current_state = t.current_state + 1 }

let map_variable t ~var =
  { t with proc_vars = Map.set t.proc_vars ~key:var ~data:t.current_state }
;;

let get_state_for t ~var = Map.find_exn t.proc_vars var
let participant t = t.participant
let state_var t = t.state_var

let register_variable t ~var ~max_value =
  { t with registered_vars = Map.set t.registered_vars ~key:var ~data:max_value }
;;

let register_action_var t action ~max_value =
  let var_name = Action.to_string action in
  { t with registered_vars = Map.set t.registered_vars ~key:var_name ~data:max_value }
;;

let get_registered_variables t =
  Map.to_alist t.registered_vars
