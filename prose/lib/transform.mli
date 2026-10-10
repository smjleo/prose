open! Core

(**
  Transform the probabilities of transitions to all have equal probabilities.
    e.g 0.3:u1, 0.7:u2, 0:u3 -> 1/3:u1, 1/3:u2, 1/3:u3

  Used for getting around zero-probability transition restrictions in PRISM,
  which allows for safety (and other non-probabilistic probability) checking
  for contexts with zero transitions. See more detail in the paper.
*)
val balance_probabilities : Prism.model -> Prism.model
