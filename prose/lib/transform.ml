open! Core
open Prism

let balance_probabilities_in_command command =
  let n = List.length command.updates in
  let f (_p, u) = Fraction (1, n), u in
  let updates = List.map command.updates ~f in
  { command with updates }
;;

let balance_probabilties_in_module pmodule =
  { pmodule with
    commands = List.map pmodule.commands ~f:balance_probabilities_in_command
  }
;;

let balance_probabilities model =
  { model with modules = List.map model.modules ~f:balance_probabilties_in_module }
;;
