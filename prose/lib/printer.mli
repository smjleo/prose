open! Core

val print_model : ?output_file:string -> ?use_unbounded_ints:bool -> Prism.model -> unit
val print_properties : ?output_file:string -> Psl.annotated_property list -> unit
