open! Core

(** A simple microbenchmarking harness.
    [iterations] controls the amount of samples taken, and
    [batch_size] (default: 1) controls the amount of times [f] is run in the inner loop.
*)
val benchmark_function
  :  iterations:int
  -> ?batch_size:int
  -> f:(unit -> 'a)
  -> unit
  -> Time_float.Span.t list
