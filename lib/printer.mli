open! Core

val print_model : ?output_file:string -> Prism.model -> unit
val print_properties : ?output_file:string -> Psl.annotated_property list -> unit
