type property = P of bound * path_property

and bound =
  | Exact
  | Lt of float
  | Le of float
  | Gt of float
  | Ge of float

and path_property =
  | Label of string (* TODO: Should use a label type *)
  | And of path_property * path_property
  | Or of path_property * path_property
  | Implies of path_property * path_property
  | G of path_property (** Globally / always *)
  | F of path_property (** Future / eventually *)
